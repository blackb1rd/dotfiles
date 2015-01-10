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
  sudo apt-get update
  sudo apt-get install -y ncurses-term silversearcher-ag vim tmux
fi

# Get the current directory
current_dir="$( cd "$( dirname "$0" )" && pwd )"


###############################################################################
#                            ____  _          _ _                             #
#                           / ___|| |__   ___| | |                            #
#                           \___ \| '_ \ / _ \ | |                            #
#                            ___) | | | |  __/ | |                            #
#                           |____/|_| |_|\___|_|_|                            #
#                                                                             #
###############################################################################

if [[ ! -a ~/.zshrc ]]
then
  ln -s $current_dir/shell/zshrc $HOME/.zshrc
fi

if [[ ! -a ~/.bashrc ]]
then
  ln -s $current_dir/shell/bashrc $HOME/.bashrc
fi

###############################################################################
#                ____       _                                                 #
#               |  _ \  ___| |__  _   _  __ _  __ _  ___ _ __                 #
#               | | | |/ _ \ '_ \| | | |/ _` |/ _` |/ _ \ '__|                #
#               | |_| |  __/ |_) | |_| | (_| | (_| |  __/ |                   #
#               |____/ \___|_.__/ \__,_|\__, |\__, |\___|_|                   #
#                                       |___/ |___/                           #
#                                                                             #
###############################################################################

if [[ ! -a ~/.gdbrc ]]
then
  ln -s $current_dir/debugger/gdbrc $HOME/.gdbrc
fi

if [[ ! -a ~/.cgdb/cgdbrc ]]
then
mkdir $HOME/.cgdb
  ln -s $current_dir/debugger/cgdbrc $HOME/.cgdb/cgdbrc
fi

###############################################################################
#                                   _                                         #
#                            __   _(_)_ __ ___                                #
#                            \ \ / / | '_ ` _ \                               #
#                             \ V /| | | | | | |                              #
#                              \_/ |_|_| |_| |_|                              #
#                                                                             #
###############################################################################

if [[ ! -a ~/.vimrc ]]
then
  ln -s $current_dir/vim/vimrc $HOME/.vimrc
fi

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
cp -r $current_dir/vim/bundle "$HOME/.vim/"

# Install YouCompleteMe
cd "$HOME/.vim/bundle"
cd YouCompleteMea && ./install.sh

# Install Taglist
cd ..
wget http://www.vim.org/scripts/download_script.php?src_id=19574  -O taglist_46.zip
unzip -o taglist_46.zip -d "$HOME/.vim/bundle/taglist/"
rm taglist_46.zip

# Install fonts power line
git clone https://github.com/powerline/fonts.git
cd fonts && ./install.sh
cd .. && rm -r fonts

#TODO create symbolic link for folder
