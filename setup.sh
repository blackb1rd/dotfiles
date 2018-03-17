#!/bin/sh

GITHUB_RAW_URL='https://raw.githubusercontent.com'
GITHUB_URL='https://github.com'
TEMP="/tmp"

os_release_id="$(grep -E '^ID=([a-zA-Z]*)' /etc/os-release | cut -d '=' -f 2)"
case $(uname) in
  Darwin)
    ;;
  CYGWIN_NT-*)
    ;;
  MSYS_NT-*)
    PKG_CMD_UPDATE="pacman -Sy"
    PKG_CMD_INSTALL="pacman -Suu"
    PKG_CMD_REMOVE="pacman -R"
    ;;
  FreeBSD)
    ;;
  OpenBSD)
    ;;
  DragonFly)
    ;;
  Linux)
    case "$os_release_id" in
      "arch")
        ;;
      "debian")
        PKG_CMD_UPDATE="sudo apt-get update"
        PKG_CMD_INSTALL="sudo apt-get install -y"
        PKG_CMD_REMOVE="sudo apt-get remove -y"
        PACKAGE="autoconf
                 automake
                 build-essential
                 cmake
                 curl
                 figlet
                 g++
                 git
                 htop
                 irssi
                 libbz2-dev
                 libncurses5-dev
                 libreadline-dev
                 libsqlite3-dev
                 libssl1.0-dev
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
                 tmux
                 unzip
                 wget
                 xclip
                 xz-utils
                 zlib1g-dev
                 zsh"
        ;;
      "ubuntu")
        PKG_CMD_UPDATE="sudo apt-get update"
        PKG_CMD_INSTALL="sudo apt-get install -y"
        PKG_CMD_REMOVE="sudo apt-get remove -y"
        PACKAGE="autoconf
                 automake
                 build-essential
                 cmake
                 curl
                 figlet
                 g++
                 git
                 htop
                 irssi
                 libbz2-dev
                 libncurses5-dev
                 libreadline-dev
                 libsqlite3-dev
                 libssl1.0-dev
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
                 tmux
                 unzip
                 wget
                 xclip
                 xz-utils
                 zlib1g-dev
                 zsh"
        ;;
      "elementary")
        ;;
      "fedora")
        PKG_CMD_UPDATE="sudo yum update"
        PKG_CMD_INSTALL="sudo yum install -y"
        PKG_CMD_REMOVE="sudo yum remove -y"
        ;;
      "coreos")
        ;;
      "gentoo")
        ;;
      "mageia")
        ;;
      "centos")
        PKG_CMD_UPDATE="sudo yum update"
        PKG_CMD_INSTALL="sudo yum install -y"
        PKG_CMD_REMOVE="sudo yum remove -y"
        ;;
      "opensuse"|"tumbleweed")
        ;;
      "sabayon")
        ;;
      "slackware")
        ;;
      "linuxmint")
        PKG_CMD_UPDATE="sudo apt-get update"
        PKG_CMD_INSTALL="sudo apt-get install -y"
        PKG_CMD_UPDATE="sudo apt-get remove -y"
        ;;
      *)
        ;;
    esac

    # Check if we're running on Android
    case $(uname -o 2>/dev/null) in
      Android)
        PKG_CMD_UPDATE="pkg update"
        PKG_CMD_INSTALL="pkg install"
        PKG_CMD_INSTALL="pkg uninstall"
        ;;
    esac
    ;;
  SunOS)
    ;;
  *)
    ;;
esac

usage() {
  echo "Usage: $0 [options]"
  echo ""
  echo "Options:"
  echo "  --os  OStype       Type OS to install dotfiles(Window, Linux, Android, OSX, iOS, Yun, Openwrt)"
  echo "  -a,   --all        Installing all setup"
  echo "  -b,   --basictool  Installing basic tool"
  echo "  -d,   --dot        Installing dotfiles"
  echo "  -f,   --fonts      Installing fonts"
  echo "  -l,   --latest     Compiling the latest ctags and VIM version"
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
      linux ) return 1 ;;
    android ) return 1 ;;
     termux ) return 1 ;;
    openwrt ) return 1 ;;
        yun ) return 1 ;;
        osx ) return 1 ;;
        ios ) return 1 ;;
     window ) return 1 ;;
          * ) return 0 ;;
  esac
}

# Check argument
while [ $# != 0 ]
do
  case $1 in
    --os )                  shift
                            OStype=$1
                            ;;
    -a   | --all )          all=true;;
    -b   | --basictool )    basictool=true;;
    -d   | --dot )          dot=true;;
    -f   | --fonts )        fonts=true;;
    -l   | --latest )       latest=true;;
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
  echo "Invalid input --os $OStype"
  echo ""
  usage
  exit 1
fi

if [ -z "${all}" ] \
   && [ -z "${basictool}" ] \
   && [ -z "${dot}" ] \
   && [ -z "${fonts}" ] \
   && [ -z "${perl}" ] \
   && [ -z "${python}" ] \
   && [ -z "${ycmd}" ] \
   && [ -z "${latest}" ] ; then

  echo "Need more option(installing or compiling) to be set"
  echo ""
  usage
  exit 1
fi

if [ $OStype = "window" ] ; then
  export MSYS=winsymlinks:nativestrict
  export HOME=$USERPROFILE
fi

# Install program
if [ -n "${all}" ] || [ -n "${basictool}" ] ; then
  echo "${txtbld}$(tput setaf 1)[-] Install the basic tool$(tput sgr0)"
  if [ $OStype = "linux" ] ; then
    $PKG_CMD_UPDATE
    $PKG_CMD_INSTALL $PACKAGE \
                            || { echo 'Failed to install program' ; exit 1; }
    # if did not want to install latest version
    if [ ! "${latest}" ] && [ ! "${all}" ] ; then
      $PKG_CMD_INSTALL vim ctags
    fi
  elif [ $OStype = "termux" ] ; then
      pkg install -y $PACKAGE || { echo 'Failed to install program' ; exit 1; }
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
  if [ $OStype = "linux" ] \
     || [ $OStype = "termux" ] ; then
    $PKG_CMD_REMOVE ctags

    # clone ctags
    git clone --depth 1 $GITHUB_URL/universal-ctags/ctags $TEMP/ctags
    cd $TEMP/ctags
    ./autogen.sh
    ./configure --enable-iconv
    make
    sudo make install
  elif [ $OStype = "window" ] ; then
    if [ ! -f "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\MSBuild\15.0\Bin\msbuild.exe" ]; then
      echo "msbuild.exe not found, please install MS2017"
      exit
    fi

    # clone ctags
    git clone --depth 1 $GITHUB_URL/universal-ctags/ctags $TEMP/ctags
    cd $TEMP/ctags

    # cd win32
    # compiling code
    # need to change x64 and install new platform tool set
    # C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\MSBuild\15.0\Bin\msbuild.exe
    # echo "msbuild ctags_vs2013.sln /t:clean /t:Build /p:Configuration=Release;Platform=x64 /p:PlatformToolset=v141"> build_ctags.cmd
    # echo "setx /M PATH \"%path%;C:\Program Files\ctags\\\"" >> build_ctags.cmd
    # echo "cd x64/Release" >> build_ctags.cmd
    # need permission to create folder
    # echo "mkdir \"C:\Program Files\ctags\\\"" >> build_ctags.cmd
    # echo "cp ctags.exe \"C:\Program Files\ctags\\\"" >> build_ctags.cmd
    # echo "setx /M PATH \"%PATH%;C:\Program Files\ctags\\\"" >> build_ctags.cmd
    # echo "exit" >> build_ctags.cmd
    # start build_ctags.cmd
    # sleep 20
    # rm build_ctags.cmd
  fi
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
  if [ $OStype = "linux" ] \
     || [ $OStype = "termux" ] ; then
    installfile .gdbrc debugger/gdbrc

    mkdirfolder .cgdb
    installfile .cgdb/cgdbrc debugger/cgdbrc
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
if [ -n "${all}" ] || [ "${fonts}" ] ; then
  if [ ! -d "$HOME/.fonts" ] ; then
    # Install power line fonts
    git clone --depth 1 $GITHUB_URL/powerline/fonts.git "$current_dir/fonts"
    cd "$current_dir/fonts" && ./install.sh
    cd .. && rm -rf fonts

    # Install nerd fonts
    git clone --depth 1 $GITHUB_URL/ryanoasis/nerd-fonts "$current_dir/fonts"
    cd "$current_dir/fonts" && ./install.sh
    cd .. && rm -rf fonts
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
  if [ $OStype = "linux" ] \
     || [ $OStype = "termux" ] ; then
    installfile .gitconfig git/gitconfig
  fi
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
  if [ $OStype = "linux" ] \
     || [ $OStype = "termux" ] ; then
    installfolder irssi
  fi
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
  if [ $OStype = "linux" ] \
     || [ $OStype = "termux" ] ; then
    installfile .htoprc htop/htoprc
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
  if [ $OStype = "linux" ] \
     || [ $OStype = "termux" ] ; then
    installfile .pythonrc python/pythonrc
    PIPoption="install --user --upgrade"
    PIPmodule="Cython
               SciPy
               bottleneck
               mycli
               neovim
               numexpr
               numpy
               pandas
               tensorflow"

    # install pyenv
    curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash

    pyenv install -s 2.7.11
    pyenv install -s 3.6.4

    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
    pyenv virtualenv 2.7.11 neovim2
    pyenv virtualenv 3.6.4 neovim3

    pyenv activate neovim2
    pip install $PIPmodule

    pyenv activate neovim3
    pip install $PIPmodule

    # set pyenv to system
    pyenv shell 3.6.4
    pyenv global 3.6.4
  fi
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
  if [ $OStype = "linux" ] \
     || [ $OStype = "termux" ] ; then
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
  if [ $OStype = "linux" ] \
     || [ $OStype = "termux" ] ; then
    mkdirfolder .ssh/control
    installfile .ssh/config ssh/config
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
if [ -n "${all}" ] || [ -n "${dot}" ] ; then
  if [ $OStype = "linux" ] \
     || [ $OStype = "termux" ] ; then
    if [ ! -d "$HOME/.tmux" ] ; then
      git clone $GITHUB_URL/gpakosz/.tmux.git $HOME/.tmux
    else
      git -C "$HOME/.tmux" pull
    fi

    installfile .tmux.conf tmux/tmux.conf
    installfile .tmux.conf.local tmux/tmux.conf.local
  fi
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
  if [ $OStype = "linux" ] \
     || [ $OStype = "termux" ] ; then
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
      sudo make install
      cd .. && rm -rf "$HOME/github/neovim/"
    fi
    if [ -n "${all}" ] || [ -n "${dot}" ] ; then
      mkdirfolder .vim
      mkdirfolder .vim/
      mkdirfolder .vim/backups
      mkdirfolder .vim/tmp
      mkdirfolder .vim/undo

      mkdirfolder .config/nvim

      if [ ! -d "$HOME/github/dotfiles/vim/bundle/Vundle.vim" ] ; then
        # download latest Vundle version
        mkdir -p "$HOME/github/dotfiles/vim/bundle/"
        git clone $GITHUB_URL/VundleVim/Vundle.vim.git "$HOME/github/dotfiles/vim/bundle/Vundle.vim"
      fi

      installfolder vim/bundle
      installfolder vim/colors

      # download all plugin
      nvim +PluginInstall +qall

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
      if [ $OStype = "termux" ] ; then
        patch -f $PREFIX/include/c++/v1/cstdio $current_dir/patch/youcompleteme_cstdio.patch
      fi
      cd "$HOME/.vim/bundle/YouCompleteMe"
      git submodule update --init --recursive
      git submodule -q foreach git pull -q origin master --verbose
      #cd "$current_dir/vim/bundle/YouCompleteMe/third_party/ycmd/third_party/tern_runtime"
      #sudo npm install --production
      ./install.py

      if [ $OStype = "termux" ] ; then
        patch -f -N -R $PREFIX/include/c++/v1/cstdio $current_dir/patch/youcompleteme_cstdio.patch
      fi
    fi
  elif [ $OStype = "window" ] ; then
    if [ -n "${all}" ] || [ -n "${dot}" ] ; then
      mkdirfolder .vim
      mkdirfolder .vim/tmp
      mkdirfolder .vim/backups
      mkdirfolder .vim/undo
      mkdirfolder .vim/

      installfolder vim/bundle
      installfolder vim/colors

      # Install YouCompleteMe
      cd "$current_dir/vim/bundle/YouCompleteMe"
      git submodule update --init --recursive
      git submodule -q foreach git pull -q origin master --verbose
      #cd "$current_dir/vim/bundle/YouCompleteMe/third_party/ycmd/third_party/tern_runtime"
      #sudo npm install --production
      #cd "$current_dir/vim/bundle/YouCompleteMe"
      #./install.py --tern-completer

      installfile .vim/dict.add vim/dict.add
      installfile .vim/filetype.vim vim/filetype.vim
      installfolder vim/spell
      installfile .vimrc vim/vimrc
      installfolder vim/ycm
    fi
  fi
fi
