pathadd() {
  if [ -d "$1" ]; then
    case ":$PATH:" in
      *":$1:"*) :;;
      *) PATH="${PATH:+"$PATH:"}$1";;
    esac
  fi
}

githubUpdate () {
    echo "${txtbld}$(tput setaf 1)[-] Updating $3, please wait...$(tput sgr0)"
    CurrentDir=${PWD}
    if [ ! -d "$2" ]; then
      git clone "git://github.com/$1" "$2"
    else
      cd "$2" && git pull -v
    fi
    wait
    cd $CurrentDir
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

    echo "Need more option(development or production) to be set"
    echo ""
    myupdateusage
  else
    sudo apt-get update && sudo apt-get -y upgrade
    sudo snap refresh
    nvim +PlugInstall +qall
    nvim +PlugUpdate +qall
    antigen update
    githubUpdate "gpakosz/.tmux" "$HOME/.tmux" ".tmux"
    githubUpdate "sqlmapproject/sqlmap" "$HOME/github/sqlmap" "sqlmap"
    githubUpdate "yyuu/pyenv" "$HOME/.pyenv" "pyenv"
    githubUpdate "rbenv/rbenv" "$HOME/.rbenv" "rbenv"
    pip list --outdated --format=freeze | grep -v '^\-e' | cut -d = -f 1  | xargs -n1 pip install -U
    sudo gem install rubygems-update
    sudo update_rubygems
    sudo gem update --system
    go get -u all

    if [ -n "${development}" ] ; then
      flutter upgrade
      flutter update-packages
    fi
  fi
}

myupdateusage() {
  echo "Usage: myupdate [options]"
  echo ""
  echo "Options:"
  echo "  -d,    --dev  Development update"
  echo "  -p,    --pro  Production update"
}
