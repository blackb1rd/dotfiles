#!/bin/bash

usage() {
  echo "Usage: $0 [options]"
  echo ""
  echo "Options:"
  echo "  --os OStype       Type OS to install dotfiles(Linux, Android, OSX, iOS)"
  echo "  -b, --basictool   Installing basic tool"
  echo "  -h, --help        Show basic help message and exit"
}

mkdirfolder () {
  if [[ ! -d "$HOME/$1" ]]
  then
    mkdir "$HOME/$1"
  fi
}

installfile () {
  if [[ ! -a "$HOME/$1" ]]
  then
    ln -s "$current_dir/$2" "$HOME/$1"
  fi
}

installfolder () {
  if [[ ! -d "$HOME/.$1" ]]
  then
    ln -s "$current_dir/$1" "$HOME/.$1"
  fi
}

# Check argument
while [[ $# > 1 ]]
do
  case $1 in
    --os )                  shift
                            OStype=$1
                            ;;
    -b | --basictool )      basictool=true
                            ;;
    -h | --help )           usage
                            exit
                            ;;
    * )                     usage
                            exit 1
  esac
shift
done

# Check the input of OStype
if ! [[ "${OStype,,}" =~ ^(linux|android|osx|ios)$ ]]
then
  echo "Invalid input --os $OStype"
  echo ""
  echo "To see more details $0 -h"
  exit 1
fi

# Install program
if [[ ("${OStype,,}" =~ ^(linux)$) && ($basictool) ]]
then
  # Find the DISTRIB
  DISTRIB=$(lsb_release -si)
  if [[ "${DISTRIB,,}" =~ ^(ubuntu|debian)$ ]]
  then
    echo "${txtbld}$(tput setaf 1)[-] Install the basic tool$(tput sgr0)"
    sudo apt-get update
    sudo apt-get install -y htop irssi lynx ncurses-term vim tmux python-dev \
                            build-essential cmake gocode npm node
    echo "${txtbld}$(tput setaf 4)[>] Install completed$(tput sgr0)"
  fi
fi

# Get the current directory
current_dir="$( cd "$( dirname "$0" )" && pwd )"

# Update submodule
git submodule update --init --recursive

###############################################################################
#                 ____       _                                                #
#                |  _ \  ___| |__  _   _  __ _  __ _  ___ _ __                #
#                | | | |/ _ \ '_ \| | | |/ _` |/ _` |/ _ \ '__|               #
#                | |_| |  __/ |_) | |_| | (_| | (_| |  __/ |                  #
#                |____/ \___|_.__/ \__,_|\__, |\__, |\___|_|                  #
#                                        |___/ |___/                          #
#                                                                             #
###############################################################################
if [[ "${OStype,,}" =~ ^(linux)$ ]]
then
  installfile .gdbrc debugger/gdbrc

  mkdirfolder .cgdb
  installfile .cgdb/cgdbrc debugger/cgdbrc
fi

###############################################################################
#                                  ____ _ _                                   #
#                                 / ___(_) |_                                 #
#                                | |  _| | __|                                #
#                                | |_| | | |_                                 #
#                                 \____|_|\__|                                #
#                                                                             #
###############################################################################
if [[ "${OStype,,}" =~ ^(linux)$ ]]
then
  installfile .gitconfig git/gitconfig
fi

###############################################################################
#                              ___              _                             #
#                             |_ _|_ __ ___ ___(_)                            #
#                              | || '__/ __/ __| |                            #
#                              | || |  \__ \__ \ |                            #
#                             |___|_|  |___/___/_|                            #
#                                                                             #
###############################################################################
if [[ "${OStype,,}" =~ ^(linux)$ ]]
then
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
if [[ "${OStype,,}" =~ ^(linux)$ ]]
then
  installfile .htoprc htop/htoprc
fi

###############################################################################
#                             ____  _          _ _                            #
#                            / ___|| |__   ___| | |                           #
#                            \___ \| '_ \ / _ \ | |                           #
#                             ___) | | | |  __/ | |                           #
#                            |____/|_| |_|\___|_|_|                           #
#                                                                             #
###############################################################################
if [[ "${OStype,,}" =~ ^(linux)$ ]]
then
  installfile .zshrc shell/zshrc
  installfile .bashrc shell/bashrc
fi

###############################################################################
#                          _____                                              #
#                         |_   _| __ ___  _   ___  __                         #
#                           | || '_ ` _ \| | | \ \/ /                         #
#                           | || | | | | | |_| |>  <                          #
#                           |_||_| |_| |_|\__,_/_/\_\                         #
#                                                                             #
###############################################################################
if [[ "${OStype,,}" =~ ^(linux)$ ]]
then
  installfile .tmux.conf tmux/tmux.conf
fi

###############################################################################
#                            __     ___                                       #
#                            \ \   / (_)_ __ __                               #
#                             \ \ / /| | '_ ` _ \                             #
#                              \ V / | | | | | | |                            #
#                               \_/  |_|_| |_| |_|                            #
#                                                                             #
###############################################################################
if [[ "${OStype,,}" =~ ^(linux)$ ]]
then
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
  cd "$current_dir/vim/bundle/YouCompleteMe/third_party/ycmd/third_party/tern"
  sudo npm install --production
  cd "$current_dir/vim/bundle/YouCompleteMe"
  ./install.py --tern-completer

  # Install fonts power line
  if [[ ! -d "$HOME/.fonts" ]]
  then
    git clone https://github.com/powerline/fonts.git "$current_dir/fonts"
    cd "$current_dir/fonts" && ./install.sh
    cd .. && rm -rf fonts
  fi

  installfile .vim/dict.add vim/dict.add
  installfile .vim/filetype.vim vim/filetype.vim
  installfolder vim/spell
  installfile .vimrc vim/vimrc
  installfolder vim/ycm
fi
