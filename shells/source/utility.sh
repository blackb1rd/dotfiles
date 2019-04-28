pathadd() {
  if [ -d "$1" ]; then
    case ":$PATH:" in
      *":$1:"*) :;;
      *) PATH="${PATH:+"$PATH:"}$1";;
    esac
  fi
}

myupdate()
{
  sudo apt-get update && sudo apt-get upgrade
  nvim +PlugInstall +qall
  nvim +PlugUpdate +qall
  antigen update
}
