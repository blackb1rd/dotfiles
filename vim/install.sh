#!/bin/sh
if [ ! -d "$HOME/.vim" ]; then
	mkdir "$HOME/.vim"
fi
if [ ! -d "$HOME/.vim/tmp" ]; then
	mkdir "$HOME/.vim/tmp"
fi
if [ ! -d "$HOME/.vim/backups" ]; then
	mkdir "$HOME/.vim/backups"
fi
if [ ! -d "$HOME/.vim/undo" ]; then
	mkdir "$HOME/.vim/undo"
fi

# Install bundle
cp -r bundle "$HOME/.vim/"
cd "$HOME/.vim/bundle"

# Install YouCompleteMe
cd YouCompleteMea && ./install.sh
cd ..

#Taglist
wget http://www.vim.org/scripts/download_script.php?src_id=19574  -O taglist_46.zip
unzip -o taglist_46.zip -d "$HOME/.vim/bundle/taglist/"
rm taglist_46.zip

# Install fonts power line
git clone https://github.com/powerline/fonts.git
cd fonts && ./install.sh
cd .. && rm -r fonts
