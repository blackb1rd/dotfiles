#!/bin/bash

# Get the current directory
current_dir="$( cd "$( dirname "$0" )" && pwd )"

ncolors=$(tput colors)
if [[ $ncolors != 256 ]]
then
  apt-get install ncurses-term
fi

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
