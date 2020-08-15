#!/bin/sh

pathadd() {
  if [ -d "$1" ]; then
    case ":$PATH:" in
      *":$1:"*) :;;
      *) PATH="${PATH:+"$PATH:"}$1";;
    esac
  fi
}

githubUpdate () {
    txtbld=$(tput bold)
    echo "${txtbld}$(tput setaf 1)[-] Updating $3, please wait...$(tput sgr0)"
    CurrentDir=${PWD}
    if [ ! -d "$2" ]; then
      git clone "git://github.com/$1" "$2"
    else
      cd "$2" && git pull -v
    fi
    wait
    cd "$CurrentDir" || exit 1
    echo "${txtbld}$(tput setaf 4)[>] $3 updated successfully!$(tput sgr0)"
  }

myupdate()
{
  # Check argument
  while [ $# != 0 ]
  do
    case $1 in
      -d    | --dev )          development=true;;
      -p    | --pro )          production=true;;
      * )                      myupdateusage;exit 1
    esac
    shift
  done

  if [ -z "${development}" ] \
     && [ -z "${production}" ] ; then

  echo "Need more option('-d' development or '-p' production) to be set"
    echo ""
    myupdateusage
  else
    sudo apt-get update && sudo apt-get -y upgrade && sudo apt-get -y dist-upgrade
    sudo snap refresh
    nvim +PlugInstall +qall
    nvim +PlugUpdate +qall
    curl -sfL git.io/antibody | sh -s - -b /usr/local/bin
    githubUpdate "gpakosz/.tmux" "$HOME/.tmux" ".tmux"
    githubUpdate "sqlmapproject/sqlmap" "$HOME/github/sqlmap" "sqlmap"
    githubUpdate "yyuu/pyenv" "$HOME/.pyenv" "pyenv"
    githubUpdate "rbenv/rbenv" "$HOME/.rbenv" "rbenv"
    githubUpdate "rbenv/ruby-build" "$HOME/.rbenv/plugins/ruby-build" "ruby-build"
    pip list --outdated --format=freeze | grep -v '^\-e' | cut -d = -f 1  | xargs -n1 pip install -U
    rustup update
    sudo gem install rubygems-update
    sudo update_rubygems
    sudo gem update --system
    go get -u all

    if [ -n "${development}" ] ; then
      flutter upgrade
      flutter update-packages
    fi
    antibody update
    antibody bundle < "$HOME/.zsh_plugins.txt" > "$HOME/.zsh_plugins.sh"
  fi
}

myupdateusage() {
  echo "Usage: myupdate [options]"
  echo ""
  echo "Options:"
  echo "  -d,    --dev  Development update"
  echo "  -p,    --pro  Production update"
}
