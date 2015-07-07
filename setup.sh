#!/bin/bash

usage() {
  echo "Usage: $0 [options]"
  echo ""
  echo "Options:"
  echo "  --os OStype   Type OS to install dotfiles(Linux, Android, OSX, iOS)"
  echo "  -h, --help    Show basic help message and exit"
}

# Check argument
case $1 in
  --os )                  shift
                          OStype=$1
                          ;;
  -h | --help )           usage
                          exit
                          ;;
  * )                     usage
                          exit 1
esac

# Check the input of OStype
if ! [[ "${OStype,,}" =~ ^(linux|android|osx|ios)$ ]]
then
  echo "Invalid input --os $OStype"
  echo ""
  echo "To see more details $0 -h"
  exit 1
fi

# Install program
if [[ "${OStype,,}" =~ ^(linux)$ ]]
then
  # Find the DISTRIB
  DISTRIB=$(lsb_release -si)
  if [[ "${DISTRIB,,}" =~ ^(ubuntu|debian)$ ]]
  then
    echo "${txtbld}$(tput setaf 1)[-] Install the basic tool$(tput sgr0)"
    sudo apt-get update
    sudo apt-get install -y htop irssi lynx ncurses-term vim tmux
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
  if [[ ! -a ~/.gdbrc ]]
  then
    ln -s $current_dir/debugger/gdbrc $HOME/.gdbrc
  fi

  if [[ ! -a ~/.cgdb/cgdbrc ]]
  then
    mkdir $HOME/.cgdb
    ln -s $current_dir/debugger/cgdbrc $HOME/.cgdb/cgdbrc
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
if [[ "${OStype,,}" =~ ^(linux)$ ]]
then
  if [[ ! -a ~/.gitconfig ]]
  then
    ln -s $current_dir/git/gitconfig $HOME/.gitconfig
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
if [[ "${OStype,,}" =~ ^(linux)$ ]]
then
  if [[ ! -d $HOME/.irssi ]]
  then
    ln -s $current_dir/irssi $HOME/.irssi
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
if [[ "${OStype,,}" =~ ^(linux)$ ]]
then
  if [[ ! -a $HOME/.htoprc ]]
  then
    ln -s $current_dir/htop/htoprc $HOME/.htoprc
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
if [[ "${OStype,,}" =~ ^(linux)$ ]]
then
  if [[ ! -a ~/.zshrc ]]
  then
    ln -s $current_dir/shell/zshrc $HOME/.zshrc
  fi

  if [[ ! -a ~/.bashrc ]]
  then
    ln -s $current_dir/shell/bashrc $HOME/.bashrc
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
if [[ "${OStype,,}" =~ ^(linux)$ ]]
then
  if [[ ! -a ~/.tmux.conf ]]
  then
    ln -s $current_dir/tmux/tmux.conf $HOME/.tmux.conf
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
if [[ "${OStype,,}" =~ ^(linux)$ ]]
then

  if [[ ! -d "$HOME/.vim" ]]
  then
    mkdir "$HOME/.vim"
  fi

  if [[ ! -d "$HOME/.vim/tmp" ]]
  then
    mkdir "$HOME/.vim/tmp"
  fi

  if [[ ! -d "$HOME/.vim/backups" ]]
  then
    mkdir "$HOME/.vim/backups"
  fi

  if [[ ! -d "$HOME/.vim/undo" ]]
  then
    mkdir "$HOME/.vim/undo"
  fi

  # Install bundle
  if [[ ! -d "$HOME/.vim/bundle" ]]
  then
    ln -s $current_dir/vim/bundle "$HOME/.vim/bundle"
  fi

  # Install bundle
  if [[ ! -d "$HOME/.vim/colors" ]]
  then
    ln -s $current_dir/vim/colors "$HOME/.vim/colors"
  fi

  # Install YouCompleteMe
  cd "$current_dir/vim/bundle"
  cd YouCompleteMe
  git submodule update --init --recursive
  ./install.sh

  # Install fonts power line
  if [[ ! -d "$HOME/.fonts" ]]
  then
    git clone https://github.com/powerline/fonts.git "$current_dir/fonts"
    cd "$current_dir/fonts" && ./install.sh
    cd .. && rm -rf fonts
  fi

  # Install dict.add
  if [[ ! -a ~/.vim/dict.add ]]
  then
    ln -s $current_dir/vim/dict.add $HOME/.vim/dict.add
  fi

  # Install filetype.vim
  if [[ ! -a ~/.vim/filetype.vim ]]
  then
    ln -s $current_dir/vim/filetype.vim $HOME/.vim/filetype.vim
  fi

  # Install spell
  if [[ ! -d ~/.vim/spell ]]
  then
    ln -s $current_dir/vim/spell $HOME/.vim/spell
  fi

  # Install .vimrc
  if [[ ! -a ~/.vimrc ]]
  then
    ln -s $current_dir/vim/vimrc $HOME/.vimrc
  fi

  # Install ycm
  if [[ ! -d ~/.vim/ycm ]]
  then
    ln -s $current_dir/vim/ycm $HOME/.vim/ycm
  fi
fi
