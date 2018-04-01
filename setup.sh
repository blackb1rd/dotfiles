#!/bin/sh

. shells/source/utility

GITHUB_RAW_URL='https://raw.githubusercontent.com'
GITHUB_URL='https://github.com'
TEMP="/tmp"
ROOT_PERM=""
USRPREFIX="/usr/local"
PYTHON2_VERSION="2.7.14"
PYTHON3_VERSION="3.6.4"
PYTHON3_MAJOR_VERSION=$(echo $PYTHON3_VERSION | cut -c 1-3)

case $(uname) in
  Darwin)
    OStype=Darwin
    ;;
  CYGWIN_NT-*)
    OStype=CYGWIN_NT
    ;;
  MSYS_NT-*)
    OStype=MSYS_NT
    PKG_CMD_UPDATE="pacman -Sy"
    PKG_CMD_INSTALL="pacman -Suu"
    PKG_CMD_REMOVE="pacman -R"
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
      case "$os_release_id" in
        "arch")
          OStype=arch
          ;;
        "debian")
          OStype=debian
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
                   git
                   golang-go
                   htop
                   irssi
                   libbz2-dev
                   libevent-dev
                   libncurses5-dev
                   libreadline-dev
                   libsqlite3-dev
                   libssl-dev
                   libtool
                   llvm
                   lynx
                   make
                   ninja-build
                   nodejs
                   pkg-config
                   python-dev
                   python3-dev
                   ruby-dev
                   tk-dev
                   unzip
                   wget
                   xclip
                   xz-utils
                   zlib1g-dev
                   zsh"
          PIPmodule="Cython
                     SciPy
                     bottleneck
                     mycli
                     neovim
                     numexpr
                     numpy
                     pandas
                     tensorflow
                     torrench"
          ;;
        "ubuntu")
          OStype=ubuntu
          ROOT_PERM="sudo"
          PKG_CMD_UPDATE="$ROOT_PERM apt-get update"
          PKG_CMD_INSTALL="$ROOT_PERM apt-get install -y"
          PKG_CMD_REMOVE="$ROOT_PERM apt-get remove -y"
          PKG_CMD_ADD_REPO="$ROOT_PERM add-apt-repository -y"
          PACKAGE="autoconf
                   automake
                   build-essential
                   curl
                   figlet
                   g++
                   git
                   htop
                   irssi
                   libbz2-dev
                   libevent-dev
                   libncurses5-dev
                   libreadline-dev
                   libsqlite3-dev
                   libssl-dev
                   libtool
                   llvm
                   lynx
                   make
                   ninja-build
                   nodejs
                   pkg-config
                   python-dev
                   python3-dev
                   ruby-dev
                   tk-dev
                   unzip
                   wget
                   xclip
                   xz-utils
                   zlib1g-dev
                   zsh"
          if [ $os_version_id = "14.04" ] ; then
            REPOSITORY="ppa:gophers/archive"
            PACKAGE="$PACKAGE
                     cmake3
                     golang-1.10-go"
          else
            REPOSITORY="ppa:longsleep/golang-backports"
            PACKAGE="$PACKAGE
                     cmake
                     golang-go"
          fi
          PIPmodule="Cython
                     SciPy
                     bottleneck
                     mycli
                     neovim
                     numexpr
                     numpy
                     pandas
                     tensorflow
                     torrench"
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
          PIPmodule="Cython
                     SciPy
                     bottleneck
                     mycli
                     neovim
                     numexpr
                     numpy
                     pandas
                     tensorflow
                     torrench"
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
          PIPmodule="Cython
                     SciPy
                     bottleneck
                     mycli
                     neovim
                     numexpr
                     numpy
                     pandas
                     tensorflow
                     torrench"
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
          PIPmodule="Cython
                     SciPy
                     bottleneck
                     mycli
                     neovim
                     numexpr
                     numpy
                     pandas
                     tensorflow
                     torrench"
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
                   neovim
                   numexpr
                   numpy
                   pandas
                   torrench"
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
  echo "  -a,   --all        Installing all setup"
  echo "  -b,   --basictool  Installing basic tool"
  echo "  -d,   --dot        Installing dotfiles"
  echo "  -f,   --fonts      Installing fonts"
  echo "  -l,   --latest     Compiling the latest ctags and VIM version"
  echo "  -go,  --golang     Installing golang package"
  echo "  -pl,  --perl       Installing perl package"
  echo "  -py,  --python     Installing python package"
  echo "  -ycm, --ycmd       Compiling YouCompleteMe"
  echo "  -h,   --help       Show basic help message and exit"
}

mkdirfolder () {
  if [ ! -d "$HOME/$1" ] ; then
    mkdir "$HOME/$1"
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
    -a   | --all )          all=true;;
    -b   | --basictool )    basictool=true;;
    -d   | --dot )          dot=true;;
    -f   | --fonts )        fonts=true;;
    -l   | --latest )       latest=true;;
    -go  | --golang )       golang=true;;
    -pl  | --perl )         perl=true;;
    -py  | --python )       python=true;;
    -ycm | --ycmd )         ycmd=true;;
    -h   | --help )         usage;exit;;
    * )                     usage;exit 1
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
   && [ -z "${perl}" ] \
   && [ -z "${python}" ] \
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

# Get the current directory
current_dir="$( cd "$( dirname "$0" )" && pwd )"

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
  $PKG_CMD_REMOVE ctags

  # clone ctags
  git clone --depth 1 $GITHUB_URL/universal-ctags/ctags $TEMP/ctags
  cd $TEMP/ctags
  ./autogen.sh
  ./configure --prefix=$USRPREFIX --enable-iconv
  make
  $ROOT_PERM make install
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
  installfile .gdbrc debugger/gdbrc

  mkdirfolder .cgdb
  installfile .cgdb/cgdbrc debugger/cgdbrc
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
  if [ ! -d "$HOME/.fonts" ] ; then
    # Install power line fonts
    git clone --depth 1 $GITHUB_URL/powerline/fonts.git "$TEMP/fonts"
    cd "$TEMP/fonts" && ./install.sh
    cd $current_dir && rm -rf "$TEMP/fonts"

    # Install nerd fonts
    git clone --depth 1 $GITHUB_URL/ryanoasis/nerd-fonts "$TEMP/fonts"
    cd "$TEMP/fonts" && ./install.sh
    cd $current_dir && rm -rf "$TEMP/fonts"
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
  installfile .gitconfig git/gitconfig
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
  go get -u github.com/golang/dep/cmd/dep
  go get github.com/cenkalti/backoff
  go get github.com/mattn/go-sqlite3
  go get github.com/mmcdole/gofeed
  go get github.com/tensorflow/tensorflow/tensorflow/go
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
  installfolder irssi
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
  installfile .htoprc htop/htoprc
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
  installfile .pythonrc python/pythonrc
  PIPoption="install --user --upgrade"

  # install pyenv
  curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash

  # Adding pyenv path
  pathadd "$HOME/.pyenv/bin"

  export PYTHON_CONFIGURE_OPTS="--enable-shared"
  pyenv install -s $PYTHON2_VERSION
  pyenv install -s $PYTHON3_VERSION

  eval "$(pyenv init -)"
  eval "$(pyenv virtualenv-init -)"
  pyenv virtualenv $PYTHON2_VERSION neovim2
  pyenv virtualenv $PYTHON3_VERSION neovim3

  pyenv activate neovim2
  pip install --upgrade $PIPmodule

  pyenv activate neovim3
  pip install --upgrade $PIPmodule

  mkdirfolder .config/torrench
  wget "https://pastebin.com/raw/reymRHSL" \
   -O "$HOME/.config/torrench/config.ini"


  # set pyenv to system
  pyenv shell $PYTHON3_VERSION
  pyenv global $PYTHON3_VERSION
fi

###############################################################################
#                             ____  _          _ _                            #
#                            / ___|| |__   ___| | |                           #
#                            \___ \| '_ \ / _ \ | |                           #
#                             ___) | | | |  __/ | |                           #
#                            |____/|_| |_|\___|_|_|                           #
#                                                                             #
###############################################################################
if [ -n "${all}" ] || [ -n "${dot}" ] ; then
  if [ ! -f "$HOME/.antigen.zsh" ]; then
    curl -L git.io/antigen > $HOME/.antigen.zsh
  fi

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


    installfile .shells/$shell/transmission shells/source/transmission
    installfile .shells/$shell/utility shells/source/utility
  done
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
  mkdirfolder .ssh/control
  installfile .ssh/config ssh/config
fi

###############################################################################
#                          _____                                              #
#                         |_   _| __ ___  _   ___  __                         #
#                           | || '_ ` _ \| | | \ \/ /                         #
#                           | || | | | | | |_| |>  <                          #
#                           |_||_| |_| |_|\__,_/_/\_\                         #
#                                                                             #
###############################################################################
if [ -n "${all}" ] || [ -n "${dot}" ] ; then
  if [ ! -d "$HOME/.tmux" ] ; then
    git clone $GITHUB_URL/gpakosz/.tmux.git $HOME/.tmux
  else
    git -C "$HOME/.tmux" pull
  fi

  if [ -n "${all}" ] || [ -n "${latest}" ] ; then
    # clone tmux
    git clone --depth 1 $GITHUB_URL/tmux/tmux $TEMP/tmux
    cd $TEMP/tmux
    sh autogen.sh
    ./configure --prefix=$USRPREFIX
    make
    $ROOT_PERM make install
  fi

  installfile .tmux.conf tmux/tmux.conf
  installfile .tmux.conf.local tmux/tmux.conf.local
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
   || [ -n "${ycmd}" ] \
   || [ -n "${dot}" ] ; then
  if [ -n "${all}" ] || [ -n "${latest}" ] ; then
    # Install latest vim version
    $PKG_CMD_REMOVE vim

    echo "${txtbld}$(tput setaf 1)[-] Install the latest VIM$(tput sgr0)"

    if [ -d "$HOME/github/neovim/" ] ; then
      rm -rf "$HOME/github/neovim/"
    fi
    git clone --depth 1 $GITHUB_URL/neovim/neovim "$HOME/github/neovim/"

    cd "$HOME/github/neovim/"
    rm -r build
    make clean
    make CMAKE_BUILD_TYPE=Release
    $ROOT_PERM make install
    cd $current_dir && rm -rf "$HOME/github/neovim/"
  fi
  if [ -n "${all}" ] || [ -n "${dot}" ] ; then
    mkdirfolder .vim
    mkdirfolder .vim/
    mkdirfolder .vim/backups
    mkdirfolder .vim/tmp
    mkdirfolder .vim/undo

    mkdirfolder .config/nvim

    if [ ! -d "$HOME/.local/share/nvim/site/autoload/plug.vim" ] ; then
      curl -fLo $HOME/.local/share/nvim/site/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    fi

    installfolder vim/colors

    # download all plugin
    nvim +slient +VimEnter +PlugInstall +qall

    # vim
    # keep these confiure if use original vim
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

  fi
  if [ -n "${all}" ] || [ -n "${ycmd}" ] ; then
    # Install YouCompleteMe
    if [ $OStype = "android" ] ; then
      patch -f $PREFIX/include/c++/v1/cstdio $current_dir/patch/youcompleteme_cstdio.patch
    fi
    cd "$HOME/.vim/bundle/YouCompleteMe"
    git submodule update --init --recursive
    git submodule -q foreach git pull -q origin master --verbose
    #cd "$current_dir/vim/bundle/YouCompleteMe/third_party/ycmd/third_party/tern_runtime"
    #sudo npm install --production
    EXTRA_CMAKE_ARGS="-DPYTHON_INCLUDE_DIR=$HOME/.pyenv/versions/$PYTHON3_VERSION/include/python${PYTHON3_MAJOR_VERSION}m -DPYTHON_LIBRARY=$HOME/.pyenv/versions/$PYTHON3_VERSION/lib/libpython${PYTHON3_MAJOR_VERSION}m.so"
    echo $EXTRA_CMAKE_ARGS
    ./install.py --go-completer

    if [ $OStype = "android" ] ; then
      patch -f -N -R $PREFIX/include/c++/v1/cstdio $current_dir/patch/youcompleteme_cstdio.patch
    fi
  fi
fi
