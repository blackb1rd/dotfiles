#!/bin/bash

# Fail on unset variables: this script runs sudo/rm with interpolated paths, so
# a typo'd name must be an error, not an empty string. Every optional variable
# is given an explicit default below. `set -e` is deliberately NOT used --
# plenty of steps here are expected to fail and be recovered from.
set -u

# Resolve the repo root from $0 so the script can be run from anywhere.
current_dir="$( cd "$( dirname "$0" )" && pwd )"

# shellcheck disable=SC1091
. "$current_dir/shells/source/utility.sh"

GITHUB_RAW_URL='https://raw.githubusercontent.com'
GITHUB_FOLDER="$HOME/git/github"
GITHUB_URL='https://github.com'
TEMP="/tmp"
ROOT_PERM=""
USRPREFIX="/usr/local"

# Per-OS settings. Declared here so `set -u` has a defined value on every
# platform; the case statement below fills in the ones it supports.
OStype=""
PACKAGE=""
PIPmodule=""
# Package providing universal-ctags. MSYS2 and Termux ship it as plain "ctags"
# (MSYS2's is universal-ctags 6.x under that name); apt and brew both call it
# universal-ctags, where a bare "ctags" is only a virtual package that apt
# refuses to resolve. Never install "ctags" on those.
CTAGS_PKG="ctags"
SCOOP_PACKAGE=""
PKG_CMD_UPDATE=""
PKG_CMD_INSTALL=""
PKG_CMD_REMOVE=""
is_wsl=""
os_codename=""
DOCKER_KEYRING=""
DOCKER_LIST=""
DOCKER_REPO_URL=""

# Command-line switches, all off until parsed.
all="" ; basictool="" ; dart="" ; docker="" ; dot="" ; fonts="" ; fzf=""
golang="" ; kicad="" ; latest="" ; neovim="" ; nodejs="" ; perl="" ; python=""
ruby="" ; rust="" ; scoop="" ; shell="" ; snap="" ; tmux="" ; ycmd=""

# version
# Versions are resolved to the latest stable release at install time.
# Export any of these to pin a specific version, e.g. GOLANG_VERSION=1.22.2 ./setup.sh
GOLANG_VERSION="${GOLANG_VERSION:-}"
PYTHON3_VERSION="${PYTHON3_VERSION:-}"
RUBY_VERSION="${RUBY_VERSION:-}"
NERD_FONTS_VERSION="${NERD_FONTS_VERSION:-}"
PIPoption="install --user --upgrade"

# Used only when the upstream lookup fails (no network, upstream change, ...).
GOLANG_VERSION_FALLBACK="1.22.2"
PYTHON3_VERSION_FALLBACK="3.12.3"
RUBY_VERSION_FALLBACK="3.3.1"
NERD_FONTS_VERSION_FALLBACK="3.4.0"

# ---------------------------------------------------------------------------
# Pretty output helpers.
# Colours are computed once, and used only when stdout is a terminal that
# advertises at least 8 colours. `tput colors` reads $TERM and knows nothing
# about redirection, so the `-t 1` check is what keeps escape codes out of
# piped output and CI logs.
# ---------------------------------------------------------------------------
if [ -t 1 ] && command -v tput > /dev/null 2>&1 \
   && [ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ] 2>/dev/null ; then
  TXT_BOLD="$(tput bold)"
  TXT_RED="$(tput setaf 1)"
  TXT_BLUE="$(tput setaf 4)"
  TXT_RESET="$(tput sgr0)"
else
  TXT_BOLD="" ; TXT_RED="" ; TXT_BLUE="" ; TXT_RESET=""
fi

# info <message>  -> red  "[-] <message>"
info() { echo "${TXT_BOLD}${TXT_RED}[-] $*${TXT_RESET}" ; }
# ok [<message>]  -> blue "[>] <message>" (defaults to "Install completed")
# shellcheck disable=SC2120  # message arg is optional by design; callers may omit it
ok() { echo "${TXT_BOLD}${TXT_BLUE}[>] ${1:-Install completed}${TXT_RESET}" ; }

# ---------------------------------------------------------------------------
# Version resolution.
# Each resolver prints the latest stable version of a toolchain, or nothing
# when the lookup fails. resolve_version() wraps them so a failed lookup falls
# back to a known-good pin instead of aborting the install.
# ---------------------------------------------------------------------------

# resolve_version <name> <fallback> <resolver-fn>
# Prints the resolved version and reports which source it came from.
resolve_version() {
  _rv_name="$1" ; _rv_fallback="$2" ; _rv_resolver="$3"
  _rv_version="$("$_rv_resolver" 2> /dev/null)"
  if [ -z "$_rv_version" ] ; then
    _rv_version="$_rv_fallback"
    info "Could not resolve the latest ${_rv_name}, using ${_rv_version}" >&2
  else
    info "Latest ${_rv_name} is ${_rv_version}" >&2
  fi
  echo "$_rv_version"
}

# Latest stable Go, from the endpoint the official installer uses.
# "https://go.dev/VERSION?m=text" -> "go1.26.5\ntime 2026-..." -> "1.26.5"
latest_golang_version() {
  curl -fsSL --max-time 15 'https://go.dev/VERSION?m=text' \
    | head -n 1 \
    | sed -n 's/^go\([0-9][0-9.]*\)$/\1/p'
}

# Latest stable CPython 3.x that pyenv can build. Requires pyenv on PATH.
# Prereleases (3.14.0rc1, 3.15-dev, ...) are excluded by the X.Y.Z match.
latest_python3_version() {
  command -v pyenv > /dev/null 2>&1 || return 1
  pyenv install --list \
    | tr -d '[:blank:]' \
    | grep -E '^3\.[0-9]+\.[0-9]+$' \
    | sort -V \
    | tail -n 1
}

# Latest Nerd Fonts release, without the tag's leading "v".
# "v3.4.0" -> "3.4.0"
latest_nerd_fonts_version() {
  curl -fsSL --max-time 15 \
    'https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest' \
    | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"v\{0,1\}\([0-9][^"]*\)".*/\1/p' \
    | head -n 1
}

# Latest stable MRI Ruby that rbenv can build. Requires rbenv on PATH.
# "rbenv install --list" is already stable-only; the X.Y.Z match drops the
# jruby/truffleruby entries.
latest_ruby_version() {
  command -v rbenv > /dev/null 2>&1 || return 1
  rbenv install --list \
    | tr -d '[:blank:]' \
    | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' \
    | sort -V \
    | tail -n 1
}

# Load Homebrew into the current shell (updates PATH and USRPREFIX) when it is
# installed, checking both the Apple Silicon and Intel prefixes.
brew_env() {
  for _brew in /opt/homebrew/bin/brew /usr/local/bin/brew ; do
    if [ -x "$_brew" ] ; then
      USRPREFIX="$(dirname "$(dirname "$_brew")")"
      eval "$("$_brew" shellenv)"
      return 0
    fi
  done
  return 1
}

# True on Debian/Ubuntu-family (apt) systems.
is_debian_like() { [ "$OStype" = "debian" ] || [ "$OStype" = "ubuntu" ] ; }

case $(uname) in
  Darwin)
    OStype=Darwin

    # Load Homebrew if it is already installed (sets USRPREFIX + PATH).
    brew_env

    PKG_CMD_UPDATE="brew update"
    PKG_CMD_INSTALL="brew install"
    PKG_CMD_REMOVE="brew uninstall"
    CTAGS_PKG="universal-ctags"
    PACKAGE="autoconf
             automake
             cmake
             coreutils
             curl
             figlet
             fzf
             git
             gnupg
             htop
             irssi
             llvm
             make
             neovim
             pkg-config
             python
             ruby
             the_silver_searcher
             tmux
             universal-ctags
             unzip
             wget
             zsh"
    PIPmodule="jedi
               matplotlib
               mycli
               neovim
               numpy
               pandas
               pynvim
               Pygments
               yapf"
    ;;
  CYGWIN_NT-*)
    OStype=CYGWIN_NT
    ;;
  MINGW64_NT-*)
    OStype=MSYS_NT
    ;;
  MSYS_NT-*)
    # Re-express the repo root as a Windows-visible path for the symlinks below.
    current_dir="$(cygpath -a "$current_dir")"
    OStype=MSYS_NT
    PKG_CMD_UPDATE="pacman -Syy"
    PKG_CMD_INSTALL="pacman --needed -Su --noconfirm"
    PKG_CMD_REMOVE="pacman -R"
    PACKAGE="autoconf
             automake
             cmake
             curl
             gcc
             git
             gnupg
             gperf
             irssi
             libbz2
             libevent
             liblzma
             libreadline
             libtool
             llvm
             make
             mingw-w64-i686-cmake
             mingw-w64-i686-gcc
             mingw-w64-i686-go
             mingw-w64-i686-jansson
             mingw-w64-i686-libtool
             mingw-w64-i686-libxml2
             mingw-w64-i686-libyaml
             mingw-w64-i686-make
             mingw-w64-i686-pcre
             mingw-w64-i686-perl
             mingw-w64-i686-pkg-config
             mingw-w64-i686-unibilium
             mingw-w64-i686-xz
             mingw-w64-x86_64-cmake
             mingw-w64-x86_64-gcc
             mingw-w64-x86_64-go
             mingw-w64-x86_64-jansson
             mingw-w64-x86_64-libtool
             mingw-w64-x86_64-libxml2
             mingw-w64-x86_64-libyaml
             mingw-w64-x86_64-make
             mingw-w64-x86_64-pcre
             mingw-w64-x86_64-perl
             mingw-w64-x86_64-pkg-config
             mingw-w64-x86_64-unibilium
             mingw-w64-x86_64-xz
             pkg-config
             python3
             ruby
             unzip
             wget
             zsh"
    pathadd "/mingw64/bin"
    [ -z "${GOROOT:-}" ] && export GOROOT=/mingw64/lib/go
    [ -z "${GOPATH:-}" ] && export GOPATH=/mingw64
    ;;
  FreeBSD)
    OStype=FreeBSD
    ;;
  OpenBSD)
    OStype=OpenBSD
    ;;
  DragonFly)
    OStype=DragonFly
    ;;
  Linux)
    if [ -f "/etc/os-release" ] ; then
      os_release_id="$(grep -E '^ID=([a-zA-Z]*)' /etc/os-release | cut -d '=' -f 2)"
      os_version_id="$(grep -E '^VERSION_ID="([0-9\.]*)"' /etc/os-release | cut -d '=' -f 2 | tr -d '"')"
      # Release codename ("noble", "bookworm", ...) for the apt repo lines.
      # /etc/os-release is authoritative and always present; lsb_release is an
      # optional package, so it is only the fallback.
      os_codename="$(grep -E '^VERSION_CODENAME=' /etc/os-release | cut -d '=' -f 2 | tr -d '"')"
      [ -z "$os_codename" ] && os_codename="$(lsb_release -cs 2>/dev/null)"
      is_wsl="$(uname -a | grep -E 'Microsoft')"
      echo "os version : $os_version_id"
      PIPmodule="bottleneck
                 Cython
                 h5py
                 jedi
                 keras
                 kikit
                 matplotlib
                 mycli
                 mysqlclient
                 neovim
                 numexpr
                 numpy
                 pandas
                 pynvim
                 Pygments
                 python-language-server
                 sciPy
                 tensorflow
                 yapf"
      if [ -n "${is_wsl}" ] ; then
        SCOOP_PACKAGE="hugo-extended"
        echo "Scoop package : $SCOOP_PACKAGE"
      fi

      case "$os_release_id" in
        "debian" | "ubuntu")
          ROOT_PERM="sudo"
          PKG_CMD_UPDATE="$ROOT_PERM apt-get update"
          PKG_CMD_INSTALL="$ROOT_PERM apt-get install -y"
          PKG_CMD_REMOVE="$ROOT_PERM apt-get remove -y"
          CTAGS_PKG="universal-ctags"
          PACKAGE="apt-transport-https
                   autoconf
                   automake
                   build-essential
                   ca-certificates
                   clang
                   cmake
                   curl
                   figlet
                   g++
                   gettext
                   git
                   gnupg
                   htop
                   irssi
                   libbz2-dev
                   libevent-dev
                   libffi-dev
                   liblzma-dev
                   libncurses-dev
                   libpcre2-dev
                   libreadline-dev
                   libsqlite3-dev
                   libssl-dev
                   libtool
                   libtool-bin
                   llvm
                   lynx
                   make
                   nasm
                   neovim
                   net-tools
                   ninja-build
                   default-jre
                   default-jdk
                   pkg-config
                   python3-dev
                   ruby-dev
                   software-properties-common
                   snapd
                   sqlite3
                   tk-dev
                   tor
                   unzip
                   wget
                   xclip
                   xz-utils
                   zlib1g-dev
                   zsh"
          # Docker's apt repository is per-distro; both the URL path and the
          # signing key differ between debian and ubuntu.
          DOCKER_KEYRING="/etc/apt/keyrings/docker.gpg"
          DOCKER_LIST="/etc/apt/sources.list.d/docker.list"
          DOCKER_REPO_URL="https://download.docker.com/linux/$os_release_id"

          case "$os_release_id" in
            "debian")
              OStype=debian
              ;;
            "ubuntu")
              OStype=ubuntu
              # qemu-kvm is a virtual package with several providers, so apt
              # refuses to pick one; name the x86 emulator explicitly.
              PACKAGE="$PACKAGE
                       libmysqlclient-dev
                       nmap
                       qemu-system-x86"
              ;;
          esac
          ;;
        *)
          ;;
      esac
    fi

    # Check if we're running on Android
    case $(uname -o 2>/dev/null) in
      Android )
        OStype=Android
        PKG_CMD_UPDATE="pkg update"
        PKG_CMD_INSTALL="pkg install -y"
        PKG_CMD_REMOVE="pkg uninstall"
        PACKAGE="autoconf
                 automake
                 cmake
                 curl
                 figlet
                 fzf
                 git
                 gnupg
                 htop
                 irssi
                 libbz2
                 libevent
                 libtool
                 llvm
                 lynx
                 make
                 ncurses-utils
                 neovim
                 nodejs
                 openssh
                 pkg-config
                 python
                 ruby
                 silversearcher-ag
                 tmux
                 unzip
                 wget
                 xz-utils
                 zsh"
        PIPmodule="Cython
                   SciPy
                   bottleneck
                   mycli
                   mysqlclient
                   neovim
                   numexpr
                   numpy
                   pandas
                   python-language-server
                   yapf"
        # Termux sets both; fall back to the defaults above if it did not.
        TEMP="${TMPDIR:-$TEMP}"
        USRPREFIX="${PREFIX:-$USRPREFIX}"
        ;;
    esac
    ;;
  SunOS)
    OStype=SunOS
    ;;
  *)
    ;;
esac

usage() {
  echo "Usage: $0 [options]"
  echo ""
  echo "Options:"
  echo "  -a,    --all        Installing all setup"
  echo "  -b,    --basictool  Installing basic tool"
  echo "  -dart  --dart       Installing dart"
  echo "  -d,    --dot        Installing dotfiles"
  echo "  -dk,   --docker     Installing docker"
  echo "  -f,    --fonts      Installing fonts"
  echo "  -fzf,  --fzf        Installing fzf"
  echo "  -l,    --latest     Compiling the latest ctags and VIM version"
  echo "  -go,   --golang     Installing golang package"
  echo "  -ki,   --kicad      Installing KiCad Plugin"
  echo "  -node, --nodejs     Installing nodejs package"
  echo "  -pl,   --perl       Installing perl package"
  echo "  -py,   --python     Installing python package"
  echo "  -rb,   --ruby       Installing ruby package"
  echo "  -rs,   --rust       Installing rust package"
  echo "  -sh,   --shell      Installing shell"
  echo "  -sc,   --scoop      Installing scoop"
  echo "  -sp,   --snap       Installing snap"
  echo "  -nvim, --neovim     Compiling neovim"
  echo "  -tmux,  --tmux      Compiling tmux"
  echo "  -ycm,  --ycmd       Compiling YouCompleteMe"
  echo "  -h,    --help       Show basic help message and exit"
}

mkdirfolder () {
  if [ ! -d "$HOME/$1" ] ; then
    mkdir -p "$HOME/$1"
  fi
}

# clone_or_pull <url> <dest> [extra git-clone args...]
# Keeps re-runs of setup.sh working: a plain `git clone` into an existing
# directory is a hard error, so update instead of failing.
clone_or_pull () {
  _cp_url="$1" ; _cp_dest="$2" ; shift 2
  if [ -d "$_cp_dest/.git" ] ; then
    git -C "$_cp_dest" pull --ff-only
  else
    git clone "$@" "$_cp_url" "$_cp_dest"
  fi
}

# Symlink $HOME/$1 -> repo file $2.
# (Re)creates the link when the destination is missing OR is a broken/dangling
# symlink (its target no longer exists). `-e` is false in both of those cases
# but true for a real file or an already-valid symlink, so existing user files
# and correct links are left untouched.
installfile () {
  if [ ! -e "$HOME/$1" ] ; then
    ln -snf "$current_dir/$2" "$HOME/$1"
  fi
}

# Symlink $HOME/.$1 -> repo folder $1, with the same missing/broken handling.
installfolder () {
  if [ ! -e "$HOME/.$1" ] ; then
    ln -snf "$current_dir/$1" "$HOME/.$1"
  fi
}

# Install a macOS LaunchDaemon (root-owned, copied — launchd rejects symlinks to
# user-writable files). $1 = repo-relative plist path. Loads it immediately.
installLaunchDaemon () {
  src="$current_dir/$1"
  dst="/Library/LaunchDaemons/$(basename "$1")"
  sudo cp "$src" "$dst" \
    && sudo chown root:wheel "$dst" \
    && sudo chmod 0644 "$dst" \
    && sudo launchctl load -w "$dst" 2>/dev/null
}

checkOStype () {
  case $1 in
    debian|ubuntu ) return 1 ;;
          android ) return 1 ;;
          msys_nt ) return 1 ;;
           darwin ) return 1 ;;
                * ) return 0 ;;
  esac
}

# Check argument
while [ $# != 0 ]
do
  case $1 in
    -a    | --all )          all=true;;
    -b    | --basictool )    basictool=true;;
    -dart | --dart )         dart=true;;
    -d    | --dot )          dot=true;;
    -dk   | --docker )       docker=true;;
    -f    | --fonts )        fonts=true;;
    -fzf  | --fzf )          fzf=true;;
    -l    | --latest )       latest=true;;
    -go   | --golang )       golang=true;;
    -ki   | --kicad )        kicad=true;;
    -node | --nodejs )       nodejs=true;;
    -pl   | --perl )         perl=true;;
    -py   | --python )       python=true;;
    -rb   | --ruby )         ruby=true;;
    -rs   | --rust )         rust=true;;
    -sh   | --shell )        shell=true;;
    -sc   | --scoop )        scoop=true;;
    -sp   | --snap )         snap=true;;
    -nvim | --neovim )       neovim=true;;
    -tmux | --tmux )         tmux=true;;
    -ycm  | --ycmd )         ycmd=true;;
    -h    | --help )         usage;exit;;
    * )                      usage;exit 1
  esac
  shift
done

# Make string as lower case
OStype=$(echo "$OStype" | awk '{print tolower($0)}')

# Check the input of OStype
if checkOStype "$OStype" ; then
  # OStype is empty when uname/os-release matched nothing at all.
  echo "${OStype:-This} OS is not supported"
  echo ""
  usage
  exit 1
fi

if [ -z "${all}" ] \
   && [ -z "${basictool}" ] \
   && [ -z "${dart}" ] \
   && [ -z "${dot}" ] \
   && [ -z "${docker}" ] \
   && [ -z "${fonts}" ] \
   && [ -z "${fzf}" ] \
   && [ -z "${golang}" ] \
   && [ -z "${kicad}" ] \
   && [ -z "${nodejs}" ] \
   && [ -z "${perl}" ] \
   && [ -z "${python}" ] \
   && [ -z "${ruby}" ] \
   && [ -z "${rust}" ] \
   && [ -z "${shell}" ] \
   && [ -z "${scoop}" ] \
   && [ -z "${snap}" ] \
   && [ -z "${neovim}" ] \
   && [ -z "${tmux}" ] \
   && [ -z "${ycmd}" ] \
   && [ -z "${latest}" ] ; then

  echo "Need more option(installing or compiling) to be set"
  echo ""
  usage
  exit 1
fi

if [ "$OStype" = "msys_nt" ] ; then
  export MSYS=winsymlinks:nativestrict
  export HOME="${USERPROFILE:-$HOME}"
fi

# Install program
if [ -n "${all}" ] || [ -n "${basictool}" ] ; then
  # macOS: make sure Homebrew itself is available before anything else.
  if [ "$OStype" = "darwin" ] && ! command -v brew > /dev/null 2>&1 ; then
    info "Install Homebrew"
    bash -c "$(curl --fail --show-error --silent --location https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    brew_env
  fi

  # Debian/Ubuntu need an extra apt repository/key for docker.
  # apt-key was removed in Ubuntu 22.04 / Debian 12, so the key goes into its
  # own keyring under /etc/apt/keyrings and the repo is bound to that keyring
  # alone via `signed-by=` (rather than being trusted archive-wide).
  # The sources file is written directly rather than via add-apt-repository:
  # that only understands PPA shortcuts now and rejects a deb line carrying
  # options with "Unable to handle repository shortcut".
  if is_debian_like ; then
    info "Install the GPG key"
    $PKG_CMD_INSTALL curl ca-certificates gnupg
    $ROOT_PERM install -m 0755 -d "$(dirname "$DOCKER_KEYRING")"
    curl -fsSL "$DOCKER_REPO_URL/gpg" \
      | $ROOT_PERM gpg --batch --yes --dearmor -o "$DOCKER_KEYRING"
    $ROOT_PERM chmod a+r "$DOCKER_KEYRING"

    info "Add the docker repository"
    echo "deb [arch=$(dpkg --print-architecture) signed-by=$DOCKER_KEYRING] $DOCKER_REPO_URL $os_codename stable" \
      | $ROOT_PERM tee "$DOCKER_LIST" > /dev/null
  fi

  info "Install the basic tool"
  $PKG_CMD_UPDATE
  # shellcheck disable=SC2086
  $PKG_CMD_INSTALL $PACKAGE || { echo 'Failed to install program' ; exit 1; }

  # if did not want to install latest version
  if [ -z "${latest}" ] && [ -z "${all}" ] ; then
    $PKG_CMD_INSTALL vim "$CTAGS_PKG"
  fi
  ok
fi

###############################################################################
#                             ____  _          _ _                            #
#                            / ___|| |__   ___| | |                           #
#                            \___ \| '_ \ / _ \ | |                           #
#                             ___) | | | |  __/ | |                           #
#                            |____/|_| |_|\___|_|_|                           #
#                                                                             #
###############################################################################
if [ -n "${all}" ] || [ -n "${dot}" ] || [ -n "${shell}" ] ; then
  info "Install the shell"
  # Install the zinit plugin manager once (shells/zshrc loads it if present).
  if [ ! -f "$HOME/.local/share/zinit/zinit.git/zinit.zsh" ] ; then
    bash -c "$(curl --fail --show-error --silent --location https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"
  fi

  # for dircolor
  wget "$GITHUB_RAW_URL/trapd00r/LS_COLORS/master/lscolors.sh" -O "$HOME/.lscolors.sh"

  installfile .p10k.zsh shells/p10k.zsh

  installfile .profile shells/profile
  installfile .bashrc shells/bashrc
  installfile .zshenv shells/zshenv
  installfile .zshrc shells/zshrc
  installfile .zprofile shells/zprofile

  # source external programs
  mkdirfolder .shells
  mkdirfolder .shells/git

  # NB: not `shell` -- that is the --shell option variable checked above.
  for sh_name in bash zsh
  do
    mkdirfolder ".shells/$sh_name"

    wget "$GITHUB_RAW_URL/git/git/master/contrib/completion/git-completion.$sh_name" \
         -O "$HOME/.shells/git/git-completion.$sh_name"
  done

  mkdirfolder ".shells/source"
  mkdirfolder ".config"
  mkdirfolder ".config/environment.d"
  installfile ".shells/source/transmission.sh" "shells/source/transmission.sh"
  installfile ".shells/source/utility.sh" "shells/source/utility.sh"
  installfile ".shells/source/environment.sh" "shells/source/environment.sh"
  installfile ".shells/source/path.sh" "shells/source/path.sh"
  installfile ".config/environment.d/env.conf" "systemd/environment.d/env.conf"

  # Per-OS developer-machine system tuning.
  if [ "$OStype" = "darwin" ] ; then
    # Raise system-wide file/process limits (needs sudo).
    installLaunchDaemon launchd/limit.maxfiles.plist
    installLaunchDaemon launchd/limit.maxproc.plist

    # Touch ID for sudo (survives OS updates). pam-reattach makes it work in tmux.
    brew install pam-reattach 2>/dev/null || true
    sudo install -o root -g wheel -m 0444 "$current_dir/pam/sudo_local" /etc/pam.d/sudo_local

    # macOS system preferences (Finder, keyboard, Dock, screenshots, ...).
    sh "$current_dir/system/macos.sh"
  elif [ "$(uname)" = "Linux" ] ; then
    # GNOME desktop tweaks + system dev limits (inotify, nofile/nproc).
    sh "$current_dir/system/linux.sh"
  fi

  ok
fi

###############################################################################
#                                    _                                        #
#                                   / \   __ _                                #
#                                  / _ \ / _` |                               #
#                                 / ___ \ (_| |                               #
#                                /_/   \_\__, |                               #
#                                        |___/                                #
#                                                                             #
###############################################################################
if [ -n "${all}" ] || [ -n "${latest}" ] ; then
  info "Install the silversearcher-ag"
  if [ "$OStype" = "darwin" ] ; then
    brew install the_silver_searcher
  else
    $PKG_CMD_REMOVE silversearcher-ag

    # clone silversearcher-ag
    git clone --depth 1 $GITHUB_URL/ggreer/the_silver_searcher "$TEMP/the_silver_searcher"
    cd "$TEMP/the_silver_searcher" || exit
    ./build.sh
    make
    $ROOT_PERM make install
    cd "$current_dir" && rm -rf "$TEMP/the_silver_searcher"
  fi
  ok
fi

###############################################################################
#                            ____ _                                           #
#                           / ___| |_ __ _  __ _ ___                          #
#                          | |   | __/ _` |/ _` / __|                         #
#                          | |___| || (_| | (_| \__ \                         #
#                           \____|\__\__,_|\__, |___/                         #
#                                          |___/                              #
#                                                                             #
###############################################################################
if [ -n "${all}" ] || [ -n "${latest}" ] ; then
  info "Install the ctags"
  if [ "$OStype" = "darwin" ] ; then
    brew install "$CTAGS_PKG"
  else
    # Drop the packaged ctags before building from source. This must name the
    # real package: "ctags" is virtual on apt, so removing it silently did
    # nothing and left the distro binary in place.
    $PKG_CMD_REMOVE "$CTAGS_PKG"

    # clone ctags
    clone_or_pull "$GITHUB_URL/universal-ctags/ctags" "$TEMP/ctags" --depth 1
    cd "$TEMP/ctags" || exit
    ./autogen.sh
    ./configure --prefix="$USRPREFIX" --enable-iconv
    make
    $ROOT_PERM make install
    cd "$current_dir" && rm -rf "$TEMP/ctags"
  fi
  ok
fi

###############################################################################
#                             ____             _                              #
#                            |  _ \  __ _ _ __| |_                            #
#                            | | | |/ _` | '__| __|                           #
#                            | |_| | (_| | |  | |_                            #
#                            |____/ \__,_|_|   \__|                           #
#                                                                             #
###############################################################################
if [ -n "${all}" ] || [ -n "${dart}" ] ; then
  info "Install the dart"
  if [ "$OStype" = "darwin" ] ; then
    brew tap dart-lang/dart
    brew install dart
  else
    # Same keyring treatment as docker: apt-key no longer exists, so the
    # Dart archive key is scoped to the Dart repo via signed-by=.
    dart_keyring="/etc/apt/keyrings/dart.gpg"
    $ROOT_PERM install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://dl-ssl.google.com/linux/linux_signing_key.pub \
      | $ROOT_PERM gpg --batch --yes --dearmor -o "$dart_keyring"
    $ROOT_PERM chmod a+r "$dart_keyring"
    echo "deb [arch=$(dpkg --print-architecture) signed-by=$dart_keyring] https://storage.googleapis.com/download.dartlang.org/linux/debian stable main" \
      | $ROOT_PERM tee /etc/apt/sources.list.d/dart_stable.list > /dev/null

    $ROOT_PERM apt-get update
    $PKG_CMD_INSTALL dart
  fi
  ok

  info "Install the flutter"
  mkdir -p "$HOME/development"
  cd "$HOME/development" || exit
  if [ ! -d "$HOME/development/flutter" ] ; then
    git clone https://github.com/flutter/flutter.git -b stable --depth 1
  fi
  cd "$current_dir" || exit
  ok
fi

###############################################################################
#                 ____       _                                                #
#                |  _ \  ___| |__  _   _  __ _  __ _  ___ _ __                #
#                | | | |/ _ \ '_ \| | | |/ _` |/ _` |/ _ \ '__|               #
#                | |_| |  __/ |_) | |_| | (_| | (_| |  __/ |                  #
#                |____/ \___|_.__/ \__,_|\__, |\__, |\___|_|                  #
#                                        |___/ |___/                          #
#                                                                             #
###############################################################################
if [ -n "${all}" ] || [ -n "${dot}" ] ; then
  info "Install the debugger"
  installfile .gdbrc debugger/gdbrc

  mkdirfolder .cgdb
  installfile .cgdb/cgdbrc debugger/cgdbrc

  # install gdb-dashboard https://github.com/cyrus-and/gdb-dashboard
  wget -O "$HOME/.gdbinit" https://raw.githubusercontent.com/cyrus-and/gdb-dashboard/master/.gdbinit

  ok
fi

###############################################################################
#                        ____             _                                   #
#                       |  _ \  ___   ___| | _____ _ __                       #
#                       | | | |/ _ \ / __| |/ / _ \ '__|                      #
#                       | |_| | (_) | (__|   <  __/ |                         #
#                       |____/ \___/ \___|_|\_\___|_|                         #
#                                                                             #
###############################################################################
if [ -n "${all}" ] || [ -n "${docker}" ] ; then
  info "Install the docker"
  if [ "$OStype" = "darwin" ] ; then
    brew install --cask docker
  elif is_debian_like ; then
    $PKG_CMD_INSTALL docker-ce docker-ce-cli containerd.io
  fi
  ok
fi

###############################################################################
#                           _____           _                                 #
#                          |  ___|__  _ __ | |_ ___                           #
#                          | |_ / _ \| '_ \| __/ __|                          #
#                          |  _| (_) | | | | |_\__ \                          #
#                          |_|  \___/|_| |_|\__|___/                          #
#                                                                             #
###############################################################################
if [ -n "${fonts}" ] ; then
  if [ "$OStype" != "android" ] ; then
    info "Install the fonts"
    # Pull the single patched family from the release instead of cloning
    # ryanoasis/nerd-fonts: the archive is ~6MB, the repo is tens of GB.
    if [ "$OStype" = "darwin" ] ; then
      brew install --cask font-jetbrains-mono-nerd-font
    else
      NERD_FONTS_VERSION="${NERD_FONTS_VERSION:-$(resolve_version "Nerd Fonts" "$NERD_FONTS_VERSION_FALLBACK" latest_nerd_fonts_version)}"

      # Per-user font dir; fontconfig scans it with no root needed.
      font_dir="$HOME/.local/share/fonts/JetBrainsMonoNerdFont"
      mkdir -p "$font_dir"
      # The archive is flat (*.ttf at the root), so it unpacks straight in.
      if curl -fsSL --max-time 180 \
           "$GITHUB_URL/ryanoasis/nerd-fonts/releases/download/v${NERD_FONTS_VERSION}/JetBrainsMono.tar.xz" \
           | tar -xJ -C "$font_dir" ; then
        fc-cache -f "$font_dir"
      else
        info "Failed to install JetBrainsMono Nerd Font"
      fi
    fi

    # fontconfig: makes "monospace" resolve to the font installed above.
    mkdirfolder .config
    mkdirfolder .config/fontconfig
    installfile .config/fontconfig/fonts.conf fontconfig/fonts.conf
    ok
    # "JetBrainsMono Nerd Font 12"
  fi
fi

################################################################################
#                                 _____     __                                 #
#                                |  ___|___/ _|                                #
#                                | |_ |_  / |_                                 #
#                                |  _| / /|  _|                                #
#                                |_|  /___|_|                                  #
#                                                                              #
################################################################################
if [ -n "${all}" ] || [ -n "${fzf}" ] ; then
  if [ "$OStype" != "android" ] ; then
    info "Install the Fzf"
    if [ ! -d "$HOME/.fzf" ] ; then
      git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
    else
      git -C "$HOME/.fzf" pull
    fi
    "$HOME/.fzf/install" --all
    ok
  fi
fi

###############################################################################
#                                  ____ _ _                                   #
#                                 / ___(_) |_                                 #
#                                | |  _| | __|                                #
#                                | |_| | | |_                                 #
#                                 \____|_|\__|                                #
#                                                                             #
###############################################################################
if [ -n "${all}" ] || [ -n "${dot}" ] ; then
  info "Install the git"
  installfile .gitconfig git/gitconfig
  ok
fi

###############################################################################
#                                  ____                                       #
#                                 / ___| ___                                  #
#                                | |  _ / _ \                                 #
#                                | |_| | (_) |                                #
#                                 \____|\___/                                 #
#                                                                             #
###############################################################################
if [ -n "${all}" ] || [ -n "${golang}" ] ; then
  info "Install the go"
  if [ "$OStype" = "darwin" ] ; then
    brew install go
  else
    GOLANG_VERSION="${GOLANG_VERSION:-$(resolve_version "Go" "$GOLANG_VERSION_FALLBACK" latest_golang_version)}"

    # Build the download name for the running OS/architecture.
    go_os="$(uname -s | tr '[:upper:]' '[:lower:]')"
    case "$(uname -m)" in
      x86_64 | amd64 )  go_arch="amd64" ;;
      aarch64 | arm64 ) go_arch="arm64" ;;
      armv6l | armv7l ) go_arch="armv6l" ;;
      i386 | i686 )     go_arch="386" ;;
      * )               go_arch="amd64" ;;
    esac
    go_tar="go${GOLANG_VERSION}.${go_os}-${go_arch}.tar.gz"

    wget "https://golang.org/dl/${go_tar}"
    $ROOT_PERM rm -rf /usr/local/go
    $ROOT_PERM tar -C /usr/local -xzf "${go_tar}"
    rm "${go_tar}"
    pathadd "/usr/local/go/bin"
  fi

  # Only executables belong here. `go install` has refused non-main packages
  # since Go 1.16, and rejects `...` wildcards with a @version -- libraries
  # (goquery, ntp, backoff, mysql, go-sqlite3, gofeed, gonum, ...) are per-project
  # dependencies, added with `go get` from inside the module that needs them.
  go install github.com/FiloSottile/mkcert@latest
  go install github.com/go-delve/delve/cmd/dlv@latest
  ok
fi

###############################################################################
#                                 ____ _   _                                  #
#                                / ___| |_| | __                              #
#                               | |  _| __| |/ /                              #
#                               | |_| | |_|   <                               #
#                                \____|\__|_|\_\                              #
#                                                                             #
###############################################################################
if [ -n "${all}" ] || [ -n "${dot}" ] ; then
  info "Install the gtk"
  installfile .gtkrc-2.0 gtk-2.0/gtkrc-2.0
  mkdirfolder .config
  mkdirfolder .config/gtk-3.0
  installfile .config/gtk-3.0/settings.ini gtk-3.0/settings.ini
  ok
fi

###############################################################################
#                             _   _ _                                         #
#                            | | | | |_ ___  _ __                             #
#                            | |_| | __/ _ \| '_ \                            #
#                            |  _  | || (_) | |_) |                           #
#                            |_| |_|\__\___/| .__/                            #
#                                           |_|                               #
#                                                                             #
###############################################################################
if [ -n "${all}" ] || [ -n "${dot}" ] ; then
  info "Install the htop"
  installfile .htoprc htop/htoprc
  ok
fi

###############################################################################
#                              ___              _                             #
#                             |_ _|_ __ ___ ___(_)                            #
#                              | || '__/ __/ __| |                            #
#                              | || |  \__ \__ \ |                            #
#                             |___|_|  |___/___/_|                            #
#                                                                             #
###############################################################################
if [ -n "${all}" ] || [ -n "${dot}" ] ; then
  info "Install the irssi"
  installfolder irssi
  ok
fi

###############################################################################
#                           _  ___  ____          _                           #
#                          | |/ (_)/ ___|__ _  __| |                          #
#                          | ' /| | |   / _` |/ _` |                          #
#                          | . \| | |__| (_| | (_| |                          #
#                          |_|\_\_|\____\__,_|\__,_|                          #
#                                                                             #
###############################################################################
if [ -n "${all}" ] || [ -n "${kicad}" ] ; then
  info "Install KiCad Plugin"
  KICAD_GITHUB_PLUGIN_FOLDER="KiCad/plugins"
  mkdir -p "$GITHUB_FOLDER/$KICAD_GITHUB_PLUGIN_FOLDER"
  clone_or_pull "$GITHUB_URL/NilujePerchut/kicad_scripts.git" "$GITHUB_FOLDER/$KICAD_GITHUB_PLUGIN_FOLDER/teardrops"
  clone_or_pull "$GITHUB_URL/easyw/RF-tools-KiCAD.git" "$GITHUB_FOLDER/$KICAD_GITHUB_PLUGIN_FOLDER/RF-tools-KiCAD"
  clone_or_pull "$GITHUB_URL/easyw/kicad-action-tools.git" "$GITHUB_FOLDER/$KICAD_GITHUB_PLUGIN_FOLDER/easyw-kicad-action-tools"
  clone_or_pull "$GITHUB_URL/stimulu/kicad-round-tracks.git" "$GITHUB_FOLDER/$KICAD_GITHUB_PLUGIN_FOLDER/kicad-round-tracks"
  clone_or_pull "$GITHUB_URL/jsreynaud/kicad-action-scripts.git" "$GITHUB_FOLDER/$KICAD_GITHUB_PLUGIN_FOLDER/jsreynaud-kicad-action-scripts"
  clone_or_pull "$GITHUB_URL/xesscorp/WireIt.git" "$GITHUB_FOLDER/$KICAD_GITHUB_PLUGIN_FOLDER/WireIt"

  if [ -n "${is_wsl}" ] ; then
    # cannot create symlink
    KICAD_PLUGIN_FOLDER="/mnt/c/Program Files/KiCad/share/kicad/scripting/plugins"
    cp -r "$GITHUB_FOLDER/$KICAD_GITHUB_PLUGIN_FOLDER/teardrops/teardrops" "$KICAD_PLUGIN_FOLDER/"
    cp -r "$GITHUB_FOLDER/$KICAD_GITHUB_PLUGIN_FOLDER/RF-tools-KiCAD" "$KICAD_PLUGIN_FOLDER/"
    cp -r "$GITHUB_FOLDER/$KICAD_GITHUB_PLUGIN_FOLDER/easyw-kicad-action-tools" "$KICAD_PLUGIN_FOLDER/"
    cp -r "$GITHUB_FOLDER/$KICAD_GITHUB_PLUGIN_FOLDER/jsreynaud-kicad-action-scripts/ViaStitching" "$KICAD_PLUGIN_FOLDER/"
    cp -r "$GITHUB_FOLDER/$KICAD_GITHUB_PLUGIN_FOLDER/jsreynaud-kicad-action-scripts/CircularZone" "$KICAD_PLUGIN_FOLDER/"
    cp -r "$GITHUB_FOLDER/$KICAD_GITHUB_PLUGIN_FOLDER/WireIt" "$KICAD_PLUGIN_FOLDER/"

  else
    if [ "$OStype" = "darwin" ] ; then
      KICAD_PLUGIN_FOLDER="$HOME/Documents/KiCad/scripting/plugins"
    else
      KICAD_PLUGIN_FOLDER="$HOME/.kicad/scripting/plugins"
    fi
    mkdir -p "$KICAD_PLUGIN_FOLDER"
    ln -snf "$GITHUB_FOLDER/$KICAD_GITHUB_PLUGIN_FOLDER/teardrops/teardrops" "$KICAD_PLUGIN_FOLDER/teardrops"
    ln -snf "$GITHUB_FOLDER/$KICAD_GITHUB_PLUGIN_FOLDER/RF-tools-KiCAD" "$KICAD_PLUGIN_FOLDER/RF-tools-KiCAD"
    ln -snf "$GITHUB_FOLDER/$KICAD_GITHUB_PLUGIN_FOLDER/easyw-kicad-action-tools" "$KICAD_PLUGIN_FOLDER/easyw-kicad-action-tools"
    ln -snf "$GITHUB_FOLDER/$KICAD_GITHUB_PLUGIN_FOLDER/jsreynaud-kicad-action-scripts/ViaStitching" "$KICAD_PLUGIN_FOLDER/ViaStitching"
    ln -snf "$GITHUB_FOLDER/$KICAD_GITHUB_PLUGIN_FOLDER/jsreynaud-kicad-action-scripts/CircularZone" "$KICAD_PLUGIN_FOLDER/CircularZone"
    ln -snf "$GITHUB_FOLDER/$KICAD_GITHUB_PLUGIN_FOLDER/WireIt" "$KICAD_PLUGIN_FOLDER/WireIt"
  fi

  ok
fi

###############################################################################
#                        _   _           _       _                            #
#                       | \ | | ___   __| | ___ (_)___                        #
#                       |  \| |/ _ \ / _` |/ _ \| / __|                       #
#                       | |\  | (_) | (_| |  __/| \__ \                       #
#                       |_| \_|\___/ \__,_|\___|/ |___/                       #
#                                             |__/                            #
#                                                                             #
###############################################################################
if [ -n "${all}" ] || [ -n "${nodejs}" ] ; then
  info "Install nodejs"
  if [ "$OStype" = "darwin" ] ; then
    brew install node
  elif [ "$OStype" != "android" ] ; then
    $ROOT_PERM snap install node --classic
  fi

  if command -v npm > /dev/null 2>&1 ; then
    $ROOT_PERM npm install -g async            \
                              expo-cli         \
                              react-native-cli \
                              react            \
                              redux            \
                              mobx             \
                              netlify-cms      \
                              neovim           \
                              prettier
  fi
  ok
fi

###############################################################################
#                      ____        _   _                                      #
#                     |  _ \ _   _| |_| |__   ___  _ __                       #
#                     | |_) | | | | __| '_ \ / _ \| '_ \                      #
#                     |  __/| |_| | |_| | | | (_) | | | |                     #
#                     |_|    \__, |\__|_| |_|\___/|_| |_|                     #
#                            |___/                                            #
#                                                                             #
###############################################################################
if [ -n "${all}" ] || [ -n "${python}" ] ; then
  info "Install the python"
  installfile .pythonrc python/pythonrc

  # Android/Termux has no pyenv; it uses the pkg-provided python and pip.
  if [ "$OStype" != "android" ] ; then
    # install pyenv
    curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash

    # Adding pyenv path
    pathadd "$HOME/.pyenv/bin"
    pyenv update

    # Resolved only now: latest_python3_version needs pyenv on PATH.
    PYTHON3_VERSION="${PYTHON3_VERSION:-$(resolve_version "Python 3" "$PYTHON3_VERSION_FALLBACK" latest_python3_version)}"

    # neovim's python3 provider dlopen()s libpython, which needs a shared build.
    export PYTHON_CONFIGURE_OPTS="--enable-shared"
    pyenv install -s "$PYTHON3_VERSION"

    eval "$(pyenv init -)"

    # Make this the default interpreter, for this shell and for later ones.
    # The modules below deliberately go here rather than into a virtualenv:
    # vim/vimrc sets g:python3_host_prog to ~/.pyenv/shims/python, which
    # resolves to the *global* version. (`pyenv local` is not used -- it would
    # drop a .python-version file into whatever directory setup.sh ran from.)
    pyenv shell "$PYTHON3_VERSION"
    pyenv global "$PYTHON3_VERSION"
    pyenv rehash
  fi

  pip install --upgrade pip
  if [ -n "${PIPmodule}" ] ; then
    # shellcheck disable=SC2086
    pip $PIPoption $PIPmodule
  fi
  ok
fi

###############################################################################
#                           ____        _                                     #
#                          |  _ \ _   _| |__  _   _                           #
#                          | |_) | | | | '_ \| | | |                          #
#                          |  _ <| |_| | |_) | |_| |                          #
#                          |_| \_\\__,_|_.__/ \__, |                          #
#                                             |___/                           #
#                                                                             #
###############################################################################
if [ -n "${all}" ] || [ -n "${ruby}" ] ; then
  info "Install the ruby"
  clone_or_pull "$GITHUB_URL/rbenv/rbenv" "$HOME/.rbenv"
  cd "$HOME/.rbenv" && src/configure && make -C src
  cd "$current_dir" || exit
  pathadd "$HOME/.rbenv/bin"
  curl -fsSL $GITHUB_URL/rbenv/rbenv-installer/raw/master/bin/rbenv-doctor | bash
  mkdir -p "$(rbenv root)"/plugins
  clone_or_pull "$GITHUB_URL/rbenv/ruby-build.git" "$(rbenv root)/plugins/ruby-build"
  clone_or_pull "$GITHUB_URL/carsomyr/rbenv-bundler.git" "$(rbenv root)/plugins/bundler"
  # Resolved after ruby-build is cloned, since it supplies the version list.
  RUBY_VERSION="${RUBY_VERSION:-$(resolve_version "Ruby" "$RUBY_VERSION_FALLBACK" latest_ruby_version)}"
  rbenv install -s "$RUBY_VERSION"
  rbenv shell "$RUBY_VERSION"
  rbenv global "$RUBY_VERSION"
  gem install neovim bundler
  gem environment
  rbenv rehash
  ok
fi

###############################################################################
#                             ____            _                               #
#                            |  _ \ _   _ ___| |_                             #
#                            | |_) | | | / __| __|                            #
#                            |  _ <| |_| \__ \ |_                             #
#                            |_| \_\\__,_|___/\__|                            #
#                                                                             #
###############################################################################
if [ -n "${all}" ] || [ -n "${rust}" ] ; then
  info "Install the rust"
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  ok
fi

###############################################################################
#                         ____                                                #
#                        / ___|  ___ ___   ___  _ __                          #
#                        \___ \ / __/ _ \ / _ \| '_ \                         #
#                         ___) | (_| (_) | (_) | |_) |                        #
#                        |____/ \___\___/ \___/| .__/                         #
#                                              |_|                            #
#                                                                             #
###############################################################################
# Grouped explicitly: scoop is WSL-only under --all, but --scoop forces it.
if { [ -n "${is_wsl}" ] && [ -n "${all}" ] ; } || [ -n "${scoop}" ] ; then
  info "Install the scoop package"
  scoop install "$SCOOP_PACKAGE"
  ok
fi

###############################################################################
#                           ____                                              #
#                          / ___| _ __   __ _ _ __                            #
#                          \___ \| '_ \ / _` | '_ \                           #
#                           ___) | | | | (_| | |_) |                          #
#                          |____/|_| |_|\__,_| .__/                           #
#                                            |_|                              #
#                                                                             #
###############################################################################
# Grouped explicitly: snap is skipped on WSL under --all, but --snap forces it.
if { [ -z "${is_wsl}" ] && [ -n "${all}" ] ; } || [ -n "${snap}" ] ; then
  # snap is Linux only; skip silently on platforms without it (e.g. macOS).
  if command -v snap > /dev/null 2>&1 ; then
    info "Install the snap package"
    $ROOT_PERM snap install --channel=extended hugo
    $ROOT_PERM snap install --channel=edge shellcheck
    $ROOT_PERM snap install nvim --classic
    ok
  fi
fi


###############################################################################
#                               ____      _                                   #
#                              / ___| ___| |__                                #
#                              \___ \/ __| '_ \                               #
#                               ___) \__ \ | | |                              #
#                              |____/|___/_| |_|                              #
#                                                                             #
###############################################################################
if [ -n "${all}" ] || [ -n "${dot}" ] ; then
  if [ "${OStype}" != "msys_nt" ] ; then
    info "Install the ssh"
    mkdirfolder .ssh/control
    installfile .ssh/config ssh/config
    ok
  fi
fi

###############################################################################
#                      _____                   _ _                            #
#                     |_   _|__ _ __ _ __ ___ (_) |_ ___                      #
#                       | |/ _ \ '__| '_ ` _ \| | __/ _ \                     #
#                       | |  __/ |  | | | | | | | ||  __/                     #
#                       |_|\___|_|  |_| |_| |_|_|\__\___|                     #
#                                                                             #
###############################################################################
if [ -n "${all}" ] || [ -n "${dot}" ] ; then
  info "Install the termite"
  mkdirfolder .config
  mkdirfolder .config/termite
  installfile .config/termite/config termite/config
  ok
fi

###############################################################################
#                          _____                                              #
#                         |_   _| __ ___  _   ___  __                         #
#                           | || '_ ` _ \| | | \ \/ /                         #
#                           | || | | | | | |_| |>  <                          #
#                           |_||_| |_| |_|\__,_/_/\_\                         #
#                                                                             #
###############################################################################
if [ -n "${all}" ] || [ -n "${dot}" ] || [ -n "${tmux}" ] ; then
  info "Install the tmux"
  if [ ! -d "$HOME/.tmux" ] ; then
    git clone "$GITHUB_URL/gpakosz/.tmux.git" "$HOME/.tmux"
  else
    git -C "$HOME/.tmux" pull
  fi

  if [ -n "${all}" ] || [ -n "${latest}" ] || [ -n "${tmux}" ] ; then
    if [ "$OStype" = "darwin" ] ; then
      brew install tmux
    elif [ "$OStype" != "android" ] ; then
      # clone tmux
      git clone --depth 1 "$GITHUB_URL/tmux/tmux" "$TEMP/tmux"
      cd "$TEMP/tmux" || exit
      sh autogen.sh
      ./configure --prefix="$USRPREFIX"
      make
      $ROOT_PERM make install
      cd "$current_dir" && rm -rf "$TEMP/tmux"
    fi
  fi

  installfile .tmux.conf tmux/tmux.conf
  installfile .tmux.conf.local tmux/tmux.conf.local
  ok
fi

###############################################################################
#                            __     ___                                       #
#                            \ \   / (_)_ __ __                               #
#                             \ \ / /| | '_ ` _ \                             #
#                              \ V / | | | | | | |                            #
#                               \_/  |_|_| |_| |_|                            #
#                                                                             #
###############################################################################
if [ -n "${all}" ] \
   || [ -n "${latest}" ] \
   || [ -n "${neovim}" ] \
   || [ -n "${ycmd}" ] \
   || [ -n "${dot}" ] ; then
  info "Install the vim"
  if [ -n "${all}" ] || [ -n "${latest}" ] || [ -n "${neovim}" ] ; then
    if [ "$OStype" = "darwin" ] ; then
      brew install neovim
    elif [ "$OStype" != "android" ] && [ -n "${latest}" ] ; then
      # Install latest vim version
      $PKG_CMD_REMOVE vim

      info "Install the latest VIM"

      if [ ! -d "$HOME/github/neovim/" ] ; then
        git clone --depth 1 $GITHUB_URL/neovim/neovim "$HOME/github/neovim/"
      else
        git -C "$HOME/github/neovim/" pull
      fi

      cd "$HOME/github/neovim/" || exit
      rm -rf build
      make clean
      make CMAKE_BUILD_TYPE=Release
      $ROOT_PERM make install
      cd "$current_dir" && $ROOT_PERM rm -rf "$HOME/github/neovim/"
    fi
  fi
  if [ -n "${all}" ] || [ -n "${dot}" ] ; then
    mkdirfolder .vim
    mkdirfolder .vim/backups
    mkdirfolder .vim/tmp
    mkdirfolder .vim/undo

    mkdirfolder .config/nvim

    if [ ! -f "$HOME/.config/nvim/autoload/plug.vim" ] ; then
      curl -fLo "$HOME/.config/nvim/autoload/plug.vim" --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    fi

    installfolder vim/colors

    # vim, keep these confiure if use original vim
    installfile .vim/dict.add vim/dict.add
    installfile .vim/filetype.vim vim/filetype.vim
    installfile .vimrc vim/vimrc
    installfolder vim/spell
    installfolder vim/ycm

    # neovim
    installfile .config/nvim/dict.add vim/dict.add
    installfile .config/nvim/filetype.vim vim/filetype.vim
    installfile .config/nvim/init.vim vim/vimrc
    installfolder config/nvim/spell
    installfolder config/nvim/ycm

    # download all plugin
    nvim +PlugInstall +qall
    nvim +PlugUpdate +qall
  fi
  ok
fi

###############################################################################
#              __  __                                                         #
#              \ \/ /_ __ ___  ___  ___  _   _ _ __ ___ ___  ___              #
#               \  /| '__/ _ \/ __|/ _ \| | | | '__/ __/ _ \/ __|             #
#               /  \| | |  __/\__ \ (_) | |_| | | | (_|  __/\__ \             #
#              /_/\_\_|  \___||___/\___/ \__,_|_|  \___\___||___/             #
#                                                                             #
###############################################################################
if [ -n "${all}" ] || [ -n "${dot}" ] ; then
  info "Install the Xresources"
  installfile .Xresources X/Xresources
  ok
fi
