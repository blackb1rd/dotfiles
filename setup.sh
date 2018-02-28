#!/bin/sh

GITHUB_RAW_URL='https://raw.githubusercontent.com'
GITHUB_URL='https://github.com'
PACKAGE="cmake
         figlet
         git
         htop
         irssi
         lua
         lynx
         nodejs
         python-dev
         ruby-dev
         tmux
         zsh"

        #python3-dev
        #gocode
        #lua-dev
        #build-essential \

usage() {
  echo "Usage: $0 [options]"
  echo ""
  echo "Options:"
  echo "  --os OStype       Type OS to install dotfiles(Window, Linux, Android, OSX, iOS, Yun, Openwrt)"
  echo "  -a,  --all        Installing all setup"
  echo "  -d,  --dot        Installing dotfiles"
  echo "  -b,  --basictool  Installing basic tool"
  echo "  -f,  --fonts      Installing fonts"
  echo "  -pl, --perl       Installing perl package"
  echo "  -py, --python     Installing python package"
  echo "  -l,  --latest     Compiling the latest ctags and VIM version"
  echo "  -h,  --help       Show basic help message and exit"
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
    -a  | --all )           all=true
                            ;;
    -d  | --dot )           dot=true
                            ;;
    -b  | --basictool )     basictool=true
                            ;;
    -f  | --fonts )         fonts=true
                            ;;
    -pl | --perl )          perl=true
                            ;;
    -py | --python )        python=true
                            ;;
    -l  | --latest )        latest=true
                            ;;
    -h  | --help )          usage
                            exit
                            ;;
    * )                     usage
                            exit 1
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
   && [ -z "${dot}" ] \
   && [ -z "${basictool}" ] \
   && [ -z "${fonts}" ] \
   && [ -z "${perl}" ] \
   && [ -z "${python}" ] \
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
    # Find the DISTRIB
    DISTRIB=$(lsb_release -si | awk '{print tolower($0)}')

    if [ $DISTRIB = "ubuntu" ] || [ $DISTRIB = "debian" ] ; then
      sudo apt-get update
      sudo apt-get install -y $PACKAGE \
                              || { echo 'Failed to install program' ; exit 1; }
      # if did not want to install latest version
      if [ ! "${latest}" ] ; then
        sudo apt-get install -y vim ctags
      fi

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
    sudo apt-get remove -y ctags

    # clone ctags
    git clone $GITHUB_URL/universal-ctags/ctags $TEMP/ctags
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
    git clone $GITHUB_URL/universal-ctags/ctags $TEMP/ctags
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
    PIPmodule="numexpr bottleneck Cython SciPy numpy pandas tensorflow"

    # try to install pip module from python3 only
    PythonVer=$(pip -V | awk -F '[()]' '{ print $2 }' | awk '{print $2}' | cut -d '.' -f 1)
    PythonVer3=$(pip3 -V | awk -F '[()]' '{ print $2 }' | awk '{print $2}' | cut -d '.' -f 1)

    if [ $PythonVer = "3" ] ; then
      pip $PIPoption $PIPmodule
    elif [ $PythonVer3 = "3" ] ; then
      pip3 $PIPoption $PIPmodule
    fi

    # install pyenv
    curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash

    # set pyenv to system
    pyenv shell system
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
#                                          _                                  #
#                                  ___ ___| |__                               #
#                                 / __/ __| '_ \                              #
#                                 \__ \__ \ | | |                             #
#                                 |___/___/_| |_|                             #
#                                                                             #
###############################################################################
if [ -n "${all}" ] || [ -n "${dot}" ] ; then
  if [ $OStype = "linux" ] \
     || [ $OStype = "termux" ] ; then
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
if [ -n "${all}" ] || [ -n "${latest}" ] || [ -n "${dot}" ] ; then
  if [ $OStype = "linux" ] || [ $OStype = "termux" ] ; then
    if [ -n "${all}" ] || [ -n "${latest}" ] ; then
      # Install latest vim version
      sudo apt-get remove -y vim

      echo "${txtbld}$(tput setaf 1)[-] Install the latest VIM$(tput sgr0)"

      if [ ! -d "$HOME/github/vim/" ] ; then
        # download latest vim version
        git clone $GITHUB_URL/vim/vim "$HOME/github/vim/"
      fi

      cd "$HOME/github/vim/"

      # make sure this is the latest version
      git pull

      ./configure --with-features=huge --enable-gui --enable-luainterp \
                  --enable-perlinterp --enable-pythoninterp \
                  --enable-tclinterp --enable-python3interp \
                  --enable-rubyinterp --enable-cscope  --enable-multibyte \
                  --enable-fontset
      make
      sudo make install
    fi
    if [ -n "${all}" ] || [ -n "${dot}" ] ; then
      mkdirfolder .vim
      mkdirfolder .vim/tmp
      mkdirfolder .vim/backups
      mkdirfolder .vim/undo
      mkdirfolder .vim/

      if [ ! -d "$HOME/github/dotfiles/vim/bundle/Vundle.vim" ] ; then
        # download latest Vundle version
        mkdir -p "$HOME/github/dotfiles/vim/bundle/"
        git clone $GITHUB_URL/VundleVim/Vundle.vim.git "$HOME/github/dotfiles/vim/bundle/Vundle.vim"
      fi

      installfolder vim/bundle
      installfolder vim/colors

      # download all plugin
      vim +PluginInstall +qall

      # Install YouCompleteMe
      if [ $OStype = "termux" ] ; then
        patch -f $PREFIX/include/c++/v1/cstdio $current_dir/patch/youcompleteme_cstdio.patch
      fi
      cd "$current_dir/vim/bundle/YouCompleteMe"
      git submodule update --init --recursive
      git submodule -q foreach git pull -q origin master --verbose
      #cd "$current_dir/vim/bundle/YouCompleteMe/third_party/ycmd/third_party/tern_runtime"
      #sudo npm install --production
      cd "$current_dir/vim/bundle/YouCompleteMe"
      ./install.py

      if [ $OStype = "termux" ] ; then
        patch -f -N -R $PREFIX/include/c++/v1/cstdio $current_dir/patch/youcompleteme_cstdio.patch
      fi

      installfile .vim/dict.add vim/dict.add
      installfile .vim/filetype.vim vim/filetype.vim
      installfolder vim/spell
      installfile .vimrc vim/vimrc
      installfolder vim/ycm
    fi

    # Install fonts power line
    if [ -n "${all}" ] || [ "${fonts}" ] ; then
      if [ ! -d "$HOME/.fonts" ] ; then
        git clone $GITHUB_URL/powerline/fonts.git "$current_dir/fonts"
        cd "$current_dir/fonts" && ./install.sh
        cd .. && rm -rf fonts
        git clone $GITHUB_URL/ryanoasis/nerd-fonts "$current_dir/fonts"
        cd "$current_dir/fonts" && ./install.sh
        cd .. && rm -rf fonts
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
    # Install fonts power line
    if [ -n "${all}" ] || [ "${fonts}" ] ; then
      if [ ! -d "$HOME/.fonts" ] ; then
        git clone $GITHUB_URL/powerline/fonts.git "$current_dir/fonts"
        cd "$current_dir/fonts" && chmod a+x install.sh
        ./install.sh
        cd .. && rm -rf fonts
      fi
    fi
  fi
fi
