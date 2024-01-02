#!/bin/bash

# shellcheck disable=SC1091
. "shells/source/utility.sh"

GITHUB_RAW_URL='https://raw.githubusercontent.com'
GITHUB_FOLDER="$HOME/git/github"
GITHUB_URL='https://github.com'
TEMP="/tmp"
ROOT_PERM=""
USRPREFIX="/usr/local"
GOLANG_VERSION="1.18"
PYTHON3_VERSION="3.10.9"
PIPoption="install --user --upgrade"
RUBY_VERSION="3.1.1"
GO_TENSORFLOW_VERSION="2.8.0"

case $(uname) in
  Darwin)
    current_dir="$( cd "$( dirname "$0" )" && pwd )"
    OStype=Darwin
    ;;
  CYGWIN_NT-*)
    OStype=CYGWIN_NT
    ;;
  MINGW64_NT-*)
    OStype=MSYS_NT
    ;;
  MSYS_NT-*)
    current_dir="$(cygpath -a .)"
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
    [ -z "$GOROOT" ] && export GOROOT=/mingw64/lib/go
    [ -z "$GOPATH" ] && export GOPATH=/mingw64
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
    current_dir="$( cd "$( dirname "$0" )" && pwd )"
    if [ -f "/etc/os-release" ] ; then
      os_release_id="$(grep -E '^ID=([a-zA-Z]*)' /etc/os-release | cut -d '=' -f 2)"
      os_version_id="$(grep -E '^VERSION_ID="([0-9\.]*)"' /etc/os-release | cut -d '=' -f 2 | tr -d '"')"
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
        "arch")
          OStype=arch
          ;;
        "debian" | "ubuntu")
          ROOT_PERM="sudo"
          PKG_CMD_UPDATE="$ROOT_PERM apt-get update"
          PKG_CMD_INSTALL="$ROOT_PERM apt-get install -y"
          PKG_CMD_REMOVE="$ROOT_PERM apt-get remove -y"
          PKG_CMD_ADD_REPO="$ROOT_PERM add-apt-repository -y"
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
                   gnupg-agent
                   htop
                   irssi
                   libbz2-dev
                   libevent-dev
                   libffi-dev
                   liblzma-dev
                   libncurses5-dev
                   libpcre3-dev
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
                   openjdk-11-jre
                   openjdk-11-jdk
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
          case "$os_release_id" in
            "debian")
              OStype=debian
              ;;
            "ubuntu")
              OStype=ubuntu
              PACKAGE="$PACKAGE
                       libmysqlclient-dev
                       nmap
                       qemu-kvm"
              REPOSITORY=("deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable")
              ;;
          esac
          ;;
        "elementary")
          OStype=elementary
          ;;
        "fedora")
          OStype=fedora
          ROOT_PERM="sudo"
          PKG_CMD_UPDATE="$ROOT_PERM yum update"
          PKG_CMD_INSTALL="$ROOT_PERM yum install -y"
          PKG_CMD_REMOVE="$ROOT_PERM yum remove -y"
          PACKAGE="mysql-devel"
          ;;
        "coreos")
          OStype=coreos
          ;;
        "gentoo")
          OStype=gentoo
          ;;
        "mageia")
          OStype=mageia
          ;;
        "centos")
          OStype=centos
          ROOT_PERM="sudo"
          PKG_CMD_UPDATE="$ROOT_PERM yum update"
          PKG_CMD_INSTALL="$ROOT_PERM yum install -y"
          PKG_CMD_REMOVE="$ROOT_PERM yum remove -y"
          PACKAGE="mysql-devel"
          ;;
        "opensuse"|"tumbleweed")
          OStype=opensuse
          ;;
        "sabayon")
          OStype=sabayon
          ;;
        "slackware")
          OStype=slackware
          ;;
        "linuxmint")
          OStype=linuxmint
          ROOT_PERM="sudo"
          PKG_CMD_UPDATE="$ROOT_PERM apt-get update"
          PKG_CMD_INSTALL="$ROOT_PERM apt-get install -y"
          PKG_CMD_REMOVE="$ROOT_PERM apt-get remove -y"
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
        TEMP=$TMPDIR
        USRPREFIX=$PREFIX
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

installfile () {
  if [ ! -f "$HOME/$1" ] ; then
    ln -snf "$current_dir/$2" "$HOME/$1"
  fi
}

installfolder () {
  if [ ! -d "$HOME/.$1" ] ; then
    ln -snf "$current_dir/$1" "$HOME/.$1"
  fi
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
OStype=$(echo $OStype | awk '{print tolower($0)}')

# Check the input of OStype
if checkOStype "$OStype" ; then
  echo "$OStype OS is not supported"
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
  export HOME=$USERPROFILE
fi

# Install program
if [ -n "${all}" ] || [ -n "${basictool}" ] ; then
  txtbld=$(tput bold)
  if [ "$OStype" != "android" ] ; then
    echo "${txtbld}$(tput setaf 1)[-] Install the GPG key$(tput sgr0)"
    $PKG_CMD_INSTALL curl
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | $ROOT_PERM apt-key add -
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | $ROOT_PERM apt-key add -
  fi

  echo "${txtbld}$(tput setaf 1)[-] Install the basic tool$(tput sgr0)"
  if [ -n "${REPOSITORY[*]}" ] ; then
    for repo in "${REPOSITORY[@]}"
    do
      $PKG_CMD_ADD_REPO "$repo"
    done
  fi
  $PKG_CMD_UPDATE
  # shellcheck disable=SC2086
  $PKG_CMD_INSTALL $PACKAGE || { echo 'Failed to install program' ; exit 1; }

  # if did not want to install latest version
  if [ ! "${latest}" ] && [ ! "${all}" ] ; then
    $PKG_CMD_INSTALL vim ctags
  fi
  echo "${txtbld}$(tput setaf 4)[>] Install completed$(tput sgr0)"
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
  echo "${txtbld}$(tput setaf 1)[-] Install the shell$(tput sgr0)"
  if ! [ -x "$(command -v antibody)" ] ; then
    curl -sfL git.io/antibody | $ROOT_PERM sh -s - -b /usr/local/bin
  fi

  # for dircolor
  wget "https://raw.github.com/trapd00r/LS_COLORS/master/lscolors.sh" -O "$HOME/.lscolors.sh"

  installfile .zsh_plugins.txt shells/zsh_plugins.txt
  antibody bundle < "$HOME/.zsh_plugins.txt" > "$HOME/.zsh_plugins.sh"

  installfile .profile shells/profile
  installfile .bashrc shells/bashrc
  installfile .zshrc shells/zshrc
  installfile .zprofile shells/zprofile

  # source external programs
  mkdirfolder .shells
  mkdirfolder .shells/git

  for shell in bash zsh
  do
    mkdirfolder ".shells/$shell"

    wget "$GITHUB_RAW_URL/git/git/master/contrib/completion/git-completion.$shell" \
         -O "$HOME/.shells/git/git-completion.$shell"
  done

  mkdirfolder ".shells/source"
  installfile ".shells/source/transmission.sh" "shells/source/transmission.sh"
  installfile ".shells/source/utility.sh" "shells/source/utility.sh"
  installfile ".shells/source/path.sh" "shells/source/path.sh"

  echo "${txtbld}$(tput setaf 4)[>] Install completed$(tput sgr0)"
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
  echo "${txtbld}$(tput setaf 1)[-] Install the silversearcher-ag$(tput sgr0)"
  $PKG_CMD_REMOVE silversearcher-ag

  # clone silversearcher-ag
  git clone --depth 1 $GITHUB_URL/ggreer/the_silver_searcher "$TEMP/the_silver_searcher"
  cd "$TEMP/the_silver_searcher" || exit
  ./build.sh
  make
  $ROOT_PERM make install
  cd "$current_dir" && rm -rf "$TEMP/the_silver_searcher"
  echo "${txtbld}$(tput setaf 4)[>] Install completed$(tput sgr0)"
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
  echo "${txtbld}$(tput setaf 1)[-] Install the ctags$(tput sgr0)"
  $PKG_CMD_REMOVE ctags

  # clone ctags
  git clone --depth 1 $GITHUB_URL/universal-ctags/ctags "$TEMP/ctags"
  cd "$TEMP/ctags" || exit
  ./autogen.sh
  ./configure --prefix="$USRPREFIX" --enable-iconv
  make
  $ROOT_PERM make install
  cd "$current_dir" && rm -rf "$TEMP/ctags"
  echo "${txtbld}$(tput setaf 4)[>] Install completed$(tput sgr0)"
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
  echo "${txtbld}$(tput setaf 1)[-] Install the dart$(tput sgr0)"
  $ROOT_PERM sh -c 'wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -'
  $ROOT_PERM sh -c 'wget -qO- https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list'

  $ROOT_PERM apt-get update
  $PKG_CMD_INSTALL dart
  echo "${txtbld}$(tput setaf 4)[>] Install completed$(tput sgr0)"

  echo "${txtbld}$(tput setaf 1)[-] Install the flutter$(tput sgr0)"
  mkdir "$HOME/development"
  cd "$HOME/development" || exit
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
  echo "${txtbld}$(tput setaf 4)[>] Install completed$(tput sgr0)"
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
  echo "${txtbld}$(tput setaf 1)[-] Install the debugger$(tput sgr0)"
  installfile .gdbrc debugger/gdbrc

  mkdirfolder .cgdb
  installfile .cgdb/cgdbrc debugger/cgdbrc

  # install gdb-dashboard https://github.com/cyrus-and/gdb-dashboard
  wget -P ~ git.io/.gdbinit

  echo "${txtbld}$(tput setaf 4)[>] Install completed$(tput sgr0)"
fi

###############################################################################
#                        ____             _                                   #
#                       |  _ \  ___   ___| | _____ _ __                       #
#                       | | | |/ _ \ / __| |/ / _ \ '__|                      #
#                       | |_| | (_) | (__|   <  __/ |                         #
#                       |____/ \___/ \___|_|\_\___|_|                         #
#                                                                             #
###############################################################################
if [ -n "${all}" ] || [ "${docker}" ] ; then
  if [ "$OStype" != "android" ] ; then
    $PKG_CMD_INSTALL docker-ce docker-ce-cli containerd.io
  fi
fi

###############################################################################
#                           _____           _                                 #
#                          |  ___|__  _ __ | |_ ___                           #
#                          | |_ / _ \| '_ \| __/ __|                          #
#                          |  _| (_) | | | | |_\__ \                          #
#                          |_|  \___/|_| |_|\__|___/                          #
#                                                                             #
###############################################################################
if [ "${fonts}" ] ; then
  if [ "$OStype" != "android" ] ; then
    echo "${txtbld}$(tput setaf 1)[-] Install the fonts$(tput sgr0)"
    # Install nerd fonts
    git clone --depth 1 $GITHUB_URL/ryanoasis/nerd-fonts "$TEMP/fonts"
    cd "$TEMP/fonts" && ./install.sh "DejaVuSansMono"
    cd "$current_dir" && rm -rf "$TEMP/fonts"
    echo "${txtbld}$(tput setaf 4)[>] Install completed$(tput sgr0)"
    # "DejaVu Sans Mono Nerd Font 12"
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
if [ -n "${all}" ] || [ "${fzf}" ] ; then
  if [ "$OStype" != "android" ] ; then
    echo "${txtbld}$(tput setaf 1)[-] Install the Fzf$(tput sgr0)"
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    "$HOME/.fzf/install --all"
    echo "${txtbld}$(tput setaf 4)[>] Install completed$(tput sgr0)"
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
  echo "${txtbld}$(tput setaf 1)[-] Install the git$(tput sgr0)"
  installfile .gitconfig git/gitconfig
  echo "${txtbld}$(tput setaf 4)[>] Install completed$(tput sgr0)"
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
  echo "${txtbld}$(tput setaf 1)[-] Install the go$(tput sgr0)"
  wget "https://golang.org/dl/go$GOLANG_VERSION.linux-amd64.tar.gz"
  $ROOT_PERM tar -C /usr/local -xzf "go$GOLANG_VERSION.linux-amd64.tar.gz"
  rm "go$GOLANG_VERSION.linux-amd64.tar.gz"
  pathadd "/usr/local/go/bin"
  go install  github.com/PuerkitoBio/goquery@latest
  go install  github.com/beevik/ntp@latest
  go install  github.com/cenkalti/backoff@latest
  go install  github.com/derekparker/delve/cmd/dlv@latest
  go install  github.com/FiloSottile/mkcert@latest
  go install  github.com/go-sql-driver/mysql@latest
  go install  github.com/golang/dep/cmd/dep@latest
  go install  github.com/mattn/go-sqlite3@latest
  go install  github.com/mmcdole/gofeed@latest
  go install  gonum.org/v1/gonum/...@latest
  go install  gonum.org/v1/plot/...@latest
  go install gonum.org/v1/hdf5/...@latest
  if [ "$OStype" != "android" ] ; then
    TF_TYPE="cpu" # Change to "gpu" for GPU support
    TARGET_DIRECTORY='/usr/local'
    curl -L \
      "https://storage.googleapis.com/tensorflow/libtensorflow/libtensorflow-${TF_TYPE}-$(go env GOOS)-x86_64-${GO_TENSORFLOW_VERSION}.tar.gz" |
    $ROOT_PERM tar -C $TARGET_DIRECTORY -xz
    $ROOT_PERM ldconfig
    go install github.com/tensorflow/tensorflow/tensorflow/go@latest
  fi
  echo "${txtbld}$(tput setaf 4)[>] Install completed$(tput sgr0)"
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
  echo "${txtbld}$(tput setaf 1)[-] Install the htop$(tput sgr0)"
  installfile .htoprc htop/htoprc
  echo "${txtbld}$(tput setaf 4)[>] Install completed$(tput sgr0)"
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
  echo "${txtbld}$(tput setaf 1)[-] Install the irssi$(tput sgr0)"
  installfolder irssi
  echo "${txtbld}$(tput setaf 4)[>] Install completed$(tput sgr0)"
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
  echo "${txtbld}$(tput setaf 1)[-] Install KiCad Plugin$(tput sgr0)"
  KICAD_GITHUB_PLUGIN_FOLDER="KiCad/plugins"
  mkdir -p "$GITHUB_FOLDER/$KICAD_GITHUB_PLUGIN_FOLDER"
  git clone "$GITHUB_URL/NilujePerchut/kicad_scripts.git" "$GITHUB_FOLDER/$KICAD_GITHUB_PLUGIN_FOLDER/teardrops"
  git clone "$GITHUB_URL/easyw/RF-tools-KiCAD.git" "$GITHUB_FOLDER/$KICAD_GITHUB_PLUGIN_FOLDER/RF-tools-KiCAD"
  git clone "$GITHUB_URL/easyw/kicad-action-tools.git" "$GITHUB_FOLDER/$KICAD_GITHUB_PLUGIN_FOLDER/easyw-kicad-action-tools"
  git clone "$GITHUB_URL/stimulu/kicad-round-tracks.git" "$GITHUB_FOLDER/$KICAD_GITHUB_PLUGIN_FOLDER/kicad-round-tracks"
  git clone "$GITHUB_URL/jsreynaud/kicad-action-scripts.git" "$GITHUB_FOLDER/$KICAD_GITHUB_PLUGIN_FOLDER/jsreynaud-kicad-action-scripts"
  git clone "$GITHUB_URL/xesscorp/WireIt.git" "$GITHUB_FOLDER/$KICAD_GITHUB_PLUGIN_FOLDER/WireIt"

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
    KICAD_PLUGIN_FOLDER="$HOME/.kicad/scripting/plugins"
    ln -snf "$GITHUB_FOLDER/$KICAD_GITHUB_PLUGIN_FOLDER/teardrops/teardrops" "$KICAD_PLUGIN_FOLDER/teardrops"
    ln -snf "$GITHUB_FOLDER/$KICAD_GITHUB_PLUGIN_FOLDER/RF-tools-KiCAD" "$KICAD_PLUGIN_FOLDER/RF-tools-KiCAD"
    ln -snf "$GITHUB_FOLDER/$KICAD_GITHUB_PLUGIN_FOLDER/easyw-kicad-action-tools" "$KICAD_PLUGIN_FOLDER/easyw-kicad-action-tools"
    ln -snf "$GITHUB_FOLDER/$KICAD_GITHUB_PLUGIN_FOLDER/jsreynaud-kicad-action-scripts/ViaStitching" "$KICAD_PLUGIN_FOLDER/ViaStitching"
    ln -snf "$GITHUB_FOLDER/$KICAD_GITHUB_PLUGIN_FOLDER/jsreynaud-kicad-action-scripts/CircularZone" "$KICAD_PLUGIN_FOLDER/CircularZone"
    ln -snf "$GITHUB_FOLDER/$KICAD_GITHUB_PLUGIN_FOLDER/WireIt" "$KICAD_PLUGIN_FOLDER/WireIt"
  fi

  echo "${txtbld}$(tput setaf 4)[>] Install completed$(tput sgr0)"
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
  if [ "$OStype" != "android" ] ; then
    $PKG_CMD_REMOVE cmdtest
    $ROOT_PERM snap install node --classic
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | $ROOT_PERM tee /etc/apt/sources.list.d/yarn.list
    $PKG_CMD_INSTALL -y yarn

    $ROOT_PERM yarn global add async            \
                               expo-cli         \
                               react-native-cli \
                               react            \
                               redux            \
                               mobx             \
                               netlify-cms      \
                               neovim           \
                               prettier
  fi
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
  echo "${txtbld}$(tput setaf 1)[-] Install the python$(tput sgr0)"
  installfile .pythonrc python/pythonrc

  if [ "$OStype" != "android" ] ; then
    # install pyenv
    curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash

    # Adding pyenv path
    pathadd "$HOME/.pyenv/bin"
    pyenv update

    export PYTHON_CONFIGURE_OPTS="--enable-shared"
    pyenv install -s $PYTHON3_VERSION

    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
    pyenv virtualenv-delete -f py3nvim
    pyenv virtualenv $PYTHON3_VERSION py3nvim
    pyenv activate py3nvim
  fi
  # set pyenv to system
  pyenv shell $PYTHON3_VERSION
  pyenv local $PYTHON3_VERSION
  pyenv global $PYTHON3_VERSION

  pip install --upgrade pip
  # shellcheck disable=SC2086
  pip $PIPoption $PIPmodule
  echo "${txtbld}$(tput setaf 4)[>] Install completed$(tput sgr0)"
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
  git clone "$GITHUB_URL/rbenv/rbenv" "$HOME/.rbenv"
  cd "$HOME/.rbenv" && src/configure && make -C src
  cd "$current_dir" || exit
  pathadd "$HOME/.rbenv/bin"
  curl -fsSL $GITHUB_URL/rbenv/rbenv-installer/raw/master/bin/rbenv-doctor | bash
  mkdir -p "$(rbenv root)"/plugins
  git clone $GITHUB_URL/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build
  git clone $GITHUB_URL/carsomyr/rbenv-bundler.git "$(rbenv root)"/plugins/bundler
  rbenv install $RUBY_VERSION
  rbenv shell $RUBY_VERSION
  rbenv global $RUBY_VERSION
  gem install neovim bundler
  gem environment
  rbenv rehash
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
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
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
if [ -n "${is_wsl}" ] && [ -n "${all}" ] || [ -n "${scoop}" ] ; then
  echo "${txtbld}$(tput setaf 1)[-] Install the snap package$(tput sgr0)"
  scoop install $SCOOP_PACKAGE
  echo "${txtbld}$(tput setaf 4)[>] Install completed$(tput sgr0)"
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
if [ -z "${is_wsl}" ] && [ -n "${all}" ] || [ -n "${snap}" ] ; then
  echo "${txtbld}$(tput setaf 1)[-] Install the snap package$(tput sgr0)"
  $ROOT_PERM snap install --channel=extended hugo
  $ROOT_PERM snap install --channel=edge shellcheck
  $ROOT_PERM snap install nvim --classic
  echo "${txtbld}$(tput setaf 4)[>] Install completed$(tput sgr0)"
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
  if [ "${OStype}" != "MSYS_NT" ] ; then
    echo "${txtbld}$(tput setaf 1)[-] Install the ssh$(tput sgr0)"
    mkdirfolder .ssh/control
    installfile .ssh/config ssh/config
    echo "${txtbld}$(tput setaf 4)[>] Install completed$(tput sgr0)"
  fi
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
  echo "${txtbld}$(tput setaf 1)[-] Install the tmux$(tput sgr0)"
  if [ ! -d "$HOME/.tmux" ] ; then
    git clone "$GITHUB_URL/gpakosz/.tmux.git" "$HOME/.tmux"
  else
    git -C "$HOME/.tmux" pull
  fi

  if [ -n "${all}" ] || [ -n "${latest}" ] || [ -n "${tmux}" ] ; then
    if [ "$OStype" != "android" ] ; then
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
  echo "${txtbld}$(tput setaf 4)[>] Install completed$(tput sgr0)"
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
  echo "${txtbld}$(tput setaf 1)[-] Install the vim$(tput sgr0)"
  if [ -n "${all}" ] || [ -n "${latest}" ] || [ -n "${neovim}" ] ; then
    if [ "$OStype" != "android" ] && [ -n "${latest}" ] ; then
      # Install latest vim version
      $PKG_CMD_REMOVE vim

      echo "${txtbld}$(tput setaf 1)[-] Install the latest VIM$(tput sgr0)"

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
    mkdirfolder .vim/
    mkdirfolder .vim/backups
    mkdirfolder .vim/tmp
    mkdirfolder .vim/undo

    mkdirfolder .config/nvim

    if [ ! -d "$HOME/.config/nvim/autoload/plug.vim" ] ; then
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
fi
