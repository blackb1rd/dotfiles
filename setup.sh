#!/bin/sh

. shells/source/utility.sh

GITHUB_RAW_URL='https://raw.githubusercontent.com'
GITHUB_URL='https://github.com'
TEMP="/tmp"
ROOT_PERM=""
USRPREFIX="/usr/local"
PYTHON2_VERSION="2.7.15"
PYTHON3_VERSION="3.7.2"
PYTHON3_MAJOR_VERSION=$(echo $PYTHON3_VERSION | cut -c 1-3)
PIPoption="install --user --upgrade"
RUBY_VERSION="2.5.1"

case $(uname) in
  Darwin)
    OStype=Darwin
    ;;
  CYGWIN_NT-*)
    OStype=CYGWIN_NT
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
             mingw-w64-i686-python2
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
             mingw-w64-x86_64-python2
             mingw-w64-x86_64-unibilium
             mingw-w64-x86_64-xz
             pkg-config
             python2
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
      PIPmodule="Cython
                 SciPy
                 bottleneck
                 h5py
                 keras
                 scipy
                 matplotlib
                 mycli
                 mysqlclient
                 numexpr
                 numpy
                 pandas
                 pynvim
                 Pygments
                 python-language-server
                 tensorflow
                 yapf"
      SNAP_PACKAGE="hugo"

      case "$os_release_id" in
        "arch")
          OStype=arch
          ;;
        "debian" | "ubuntu")
          ROOT_PERM="sudo"
          PKG_CMD_UPDATE="$ROOT_PERM apt-get update"
          PKG_CMD_INSTALL="$ROOT_PERM apt-get install -y"
          PKG_CMD_REMOVE="$ROOT_PERM apt-get remove -y"
          PACKAGE="autoconf
                   automake
                   build-essential
                   cmake
                   curl
                   figlet
                   g++
                   gettext
                   git
                   htop
                   irssi
                   libbz2-dev
                   libevent-dev
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
                   ninja-build
                   openjdk-8-jre
                   openjdk-8-jdk
                   pkg-config
                   python-dev
                   python3-dev
                   qemu-kvm
                   ruby-dev
                   snapd
                   tk-dev
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
                       golang-go"
              REPOSITORY="ppa:longsleep/golang-backports"
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
                 git
                 htop
                 irssi
                 libbz2-dev
                 libevent-dev
                 libtool
                 llvm
                 lynx
                 make
                 nodejs
                 pkg-config
                 python-dev
                 ruby-dev
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
  echo "  -d,    --dot        Installing dotfiles"
  echo "  -f,    --fonts      Installing fonts"
  echo "  -l,    --latest     Compiling the latest ctags and VIM version"
  echo "  -go,   --golang     Installing golang package"
  echo "  -node, --nodejs     Installing nodejs package"
  echo "  -pl,   --perl       Installing perl package"
  echo "  -py,   --python     Installing python package"
  echo "  -rb,   --ruby       Installing ruby package"
  echo "  -rs,   --rust       Installing rust package"
  echo "  -sh,   --shell      Installing shell"
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
    ln -s "$current_dir/$2" "$HOME/$1"
  fi
}

installfolder () {
  if [ ! -d "$HOME/.$1" ] ; then
    ln -s "$current_dir/$1" "$HOME/.$1"
  fi
}

checkOStype () {
  case $1 in
    debian|ubuntu ) return 1 ;;
          android ) return 1 ;;
          msys_nt ) return 1 ;;
                * ) return 0 ;;
  esac
}

# Check argument
while [ $# != 0 ]
do
  case $1 in
    -a    | --all )          all=true;;
    -b    | --basictool )    basictool=true;;
    -d    | --dot )          dot=true;;
    -f    | --fonts )        fonts=true;;
    -l    | --latest )       latest=true;;
    -go   | --golang )       golang=true;;
    -node | --nodejs )       nodejs=true;;
    -pl   | --perl )         perl=true;;
    -py   | --python )       python=true;;
    -rb   | --ruby )         ruby=true;;
    -rs   | --rust )         rust=true;;
    -sh   | --shell )        shell=true;;
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
if checkOStype $OStype ; then
  echo "$OStype OS is not supported"
  echo ""
  usage
  exit 1
fi

if [ -z "${all}" ] \
   && [ -z "${basictool}" ] \
   && [ -z "${dot}" ] \
   && [ -z "${fonts}" ] \
   && [ -z "${golang}" ] \
   && [ -z "${nodejs}" ] \
   && [ -z "${perl}" ] \
   && [ -z "${python}" ] \
   && [ -z "${ruby}" ] \
   && [ -z "${rust}" ] \
   && [ -z "${shell}" ] \
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

if [ $OStype = "msys_nt" ] ; then
  export MSYS=winsymlinks:nativestrict
  export HOME=$USERPROFILE
fi

# Install program
if [ -n "${all}" ] || [ -n "${basictool}" ] ; then
  echo "${txtbld}$(tput setaf 1)[-] Install the basic tool$(tput sgr0)"
  if [ -n "${REPOSITORY}" ] ; then
    for repo in $REPOSITORY
    do
      $PKG_CMD_ADD_REPO $repo
    done
  fi
  $PKG_CMD_UPDATE
  $PKG_CMD_INSTALL $PACKAGE || { echo 'Failed to install program' ; exit 1; }

  # if did not want to install latest version
  if [ ! "${latest}" ] && [ ! "${all}" ] ; then
    $PKG_CMD_INSTALL vim ctags
  fi
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
  git clone --depth 1 $GITHUB_URL/ggreer/the_silver_searcher $TEMP/the_silver_searcher
  cd $TEMP/the_silver_searcher
  ./build.sh
  make
  $ROOT_PERM make install
  cd $current_dir && rm -rf "$TEMP/the_silver_searcher"
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
  git clone --depth 1 $GITHUB_URL/universal-ctags/ctags $TEMP/ctags
  cd $TEMP/ctags
  ./autogen.sh
  ./configure --prefix=$USRPREFIX --enable-iconv
  make
  $ROOT_PERM make install
  cd $current_dir && rm -rf "$TEMP/ctags"
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
#                           _____           _                                 #
#                          |  ___|__  _ __ | |_ ___                           #
#                          | |_ / _ \| '_ \| __/ __|                          #
#                          |  _| (_) | | | | |_\__ \                          #
#                          |_|  \___/|_| |_|\__|___/                          #
#                                                                             #
###############################################################################
if [ -n "${all}" ] || [ "${fonts}" ] ; then
  if [ $OStype != "android" ] ; then
    echo "${txtbld}$(tput setaf 1)[-] Install the fonts$(tput sgr0)"
    # Install power line fonts
    git clone --depth 1 $GITHUB_URL/powerline/fonts.git "$TEMP/fonts"
    cd "$TEMP/fonts" && ./install.sh
    cd $current_dir && rm -rf "$TEMP/fonts"

    # Install nerd fonts
    git clone --depth 1 $GITHUB_URL/ryanoasis/nerd-fonts "$TEMP/fonts"
    cd "$TEMP/fonts" && ./install.sh
    cd $current_dir && rm -rf "$TEMP/fonts"
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
if [ -n "${all}" ] || [ "${fonts}" ] ; then
  if [ $OStype != "android" ] ; then
    echo "${txtbld}$(tput setaf 1)[-] Install the Fzf$(tput sgr0)"
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    $HOME/.fzf/install
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
if [ -n "${all}" ] || [ -n "${dot}" ] || [ -n "${golang}" ] ; then
  echo "${txtbld}$(tput setaf 1)[-] Install the go$(tput sgr0)"
  go get -u github.com/PuerkitoBio/goquery
  go get -u github.com/beevik/ntp
  go get -u github.com/cenkalti/backoff
  go get -u github.com/derekparker/delve/cmd/dlv
  go get -u github.com/go-sql-driver/mysql
  go get -u github.com/golang/dep/cmd/dep
  go get -u github.com/mattn/go-sqlite3
  go get -u github.com/mmcdole/gofeed
  go get -u gonum.org/v1/gonum/...
  go get -u gonum.org/v1/plot/...
  go get -u gonum.org/v1/hdf5/...
  if [ $OStype != "android" ] ; then
    TF_TYPE="cpu" # Change to "gpu" for GPU support
    TARGET_DIRECTORY='/usr/local'
    curl -L \
      "https://storage.googleapis.com/tensorflow/libtensorflow/libtensorflow-${TF_TYPE}-$(go env GOOS)-x86_64-1.7.0-rc1.tar.gz" |
    $ROOT_PERM tar -C $TARGET_DIRECTORY -xz
    $ROOT_PERM ldconfig
    go get -u github.com/tensorflow/tensorflow/tensorflow/go
  fi
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
#                        _   _           _       _                            #
#                       | \ | | ___   __| | ___ (_)___                        #
#                       |  \| |/ _ \ / _` |/ _ \| / __|                       #
#                       | |\  | (_) | (_| |  __/| \__ \                       #
#                       |_| \_|\___/ \__,_|\___|/ |___/                       #
#                                             |__/                            #
#                                                                             #
###############################################################################
if [ -n "${all}" ] || [ -n "${dot}" ] || [ -n "${nodejs}" ] ; then
  if [ $OStype != "android" ] ; then
    curl -sL https://deb.nodesource.com/setup_11.x | $ROOT_PERM -E bash -
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | $ROOT_PERM apt-key add -
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
    $PKG_CMD_INSTALL -y nodejs yarn

    $ROOT_PERM yarn global add async            \
                               expo-cli         \
                               react-native-cli \
                               react            \
                               redux            \
                               mobx             \
                               neovim
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
if [ -n "${all}" ] || [ -n "${dot}" ] || [ -n "${python}" ] ; then
  echo "${txtbld}$(tput setaf 1)[-] Install the python$(tput sgr0)"
  installfile .pythonrc python/pythonrc

  if [ $OStype != "android" ] ; then
    # install pyenv
    curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash

    # Adding pyenv path
    pathadd "$HOME/.pyenv/bin"
    pyenv update

    export PYTHON_CONFIGURE_OPTS="--enable-shared"
    pyenv install -s $PYTHON2_VERSION
    pyenv install -s $PYTHON3_VERSION

    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
    pyenv virtualenv $PYTHON2_VERSION neovim2
    pyenv virtualenv $PYTHON3_VERSION neovim3

    pyenv activate neovim2
    pip install --upgrade pip
    pip $PIPoption $PIPmodule

    pyenv activate neovim3
  fi
  pip install --upgrade pip
  pip $PIPoption $PIPmodule

  mkdirfolder .config/torrench
  wget "https://pastebin.com/raw/reymRHSL" \
   -O "$HOME/.config/torrench/config.ini"

  # set pyenv to system
  pyenv shell $PYTHON3_VERSION
  pyenv global $PYTHON3_VERSION
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
if [ -n "${all}" ] || [ -n "${dot}" ] || [ -n "${ruby}" ] ; then
  git clone $GITHUB_URL/rbenv/rbenv $HOME/.rbenv
  cd $HOME/.rbenv && src/configure && make -C src
  cd $current_dir
  pathadd "$HOME/.rbenv/bin"
  curl -fsSL $GITHUB_URL/rbenv/rbenv-installer/raw/master/bin/rbenv-doctor | bash
  mkdir -p "$(rbenv root)"/plugins
  git clone $GITHUB_URL/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build
  git clone $GITHUB_URL/carsomyr/rbenv-bundler.git "$(rbenv root)"/plugins/bundler
  rbenv install $RUBY_VERSION
  rbenv shell $RUBY_VERSION
  rbenv global $RUBY_VERSION
  gem install neovim bundler
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
if [ -n "${all}" ] || [ -n "${dot}" ] || [ -n "${rust}" ] ; then
  curl https://sh.rustup.rs -sSf | sh
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
  if [ ! -f "$HOME/.antigen.zsh" ]; then
    curl -L git.io/antigen > $HOME/.antigen.zsh
    patch ~/.antigen.zsh patch/antigen_.antigen.zsh_locatiin.patch
  fi

  antigen update

  installfile .zshrc shells/zshrc
  installfile .bashrc shells/bashrc

  # source external programs
  mkdirfolder .shells
  mkdirfolder .shells/git

  for shell in bash zsh
  do
    mkdirfolder .shells/$shell

    wget "$GITHUB_RAW_URL/git/git/master/contrib/completion/git-completion.$shell" \
         -O "$HOME/.shells/git/git-completion.$shell"


    installfile .shells/$shell/transmission.sh shells/source/transmission.sh
    installfile .shells/$shell/utility.sh shells/source/utility.sh
  done
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
if [ -n "${all}" ] || [ -n "${snap}" ] ; then
  echo "${txtbld}$(tput setaf 1)[-] Install the snap package$(tput sgr0)"
  $ROOT_PERM snap install hugo
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
    git clone $GITHUB_URL/gpakosz/.tmux.git $HOME/.tmux
  else
    git -C "$HOME/.tmux" pull
  fi

  if [ -n "${all}" ] || [ -n "${latest}" ] || [ -n "${tmux}" ] ; then
    if [ $OStype != "android" ] ; then
      # clone tmux
      git clone --depth 1 $GITHUB_URL/tmux/tmux $TEMP/tmux
      cd $TEMP/tmux
      sh autogen.sh
      ./configure --prefix=$USRPREFIX
      make
      $ROOT_PERM make install
      cd $current_dir && rm -rf "$TEMP/tmux"
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
    if [ $OStype != "android" ] ; then
      # Install latest vim version
      $PKG_CMD_REMOVE vim

      echo "${txtbld}$(tput setaf 1)[-] Install the latest VIM$(tput sgr0)"

      if [ ! -d "$HOME/github/neovim/" ] ; then
        git clone --depth 1 $GITHUB_URL/neovim/neovim "$HOME/github/neovim/"
      else
        git -C "$HOME/github/neovim/" pull
      fi

      cd "$HOME/github/neovim/"
      rm -rf build
      make clean
      make CMAKE_BUILD_TYPE=Release
      $ROOT_PERM make install
      cd $current_dir && $ROOT_PERM rm -rf "$HOME/github/neovim/"
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
    nvim +slient +VimEnter +PlugInstall +qall
  fi
  if [ -n "${all}" ] || [ -n "${ycmd}" ] ; then
    echo "${txtbld}$(tput setaf 1)[-] Install YouCompleteMe$(tput sgr0)"
    cd "$HOME/.vim/bundle/YouCompleteMe"
    git pull
    git submodule update --init --recursive
    cd "$current_dir/vim/bundle/YouCompleteMe"
    if [ $OStype != "android" ] ; then
      EXTRA_CMAKE_ARGS="-DPYTHON_INCLUDE_DIR=$HOME/.pyenv/versions/$PYTHON3_VERSION/include/python${PYTHON3_MAJOR_VERSION}m -DPYTHON_LIBRARY=$HOME/.pyenv/versions/$PYTHON3_VERSION/lib/libpython${PYTHON3_MAJOR_VERSION}m.so"
    fi
    echo $EXTRA_CMAKE_ARGS
    python3 install.py --go-completer --ts-completer
  fi
  echo "${txtbld}$(tput setaf 4)[>] Install completed$(tput sgr0)"
fi
