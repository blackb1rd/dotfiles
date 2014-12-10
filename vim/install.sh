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
if [ ! -d "$HOME/.vim/colors" ]; then
	cp -r colors "$HOME/.vim/colors"
else
	cp colors/* "$HOME/.vim/colors"
fi

# Install bundle
mkdir -p "$HOME/.vim/bundle"
cd ~/.vim/bundle && \

#Taglist
wget http://www.vim.org/scripts/download_script.php?src_id=19574  -O taglist_46.zip
unzip -o taglist_46.zip -d "$HOME/.vim/bundle/taglist/"
rm taglist_46.zip
