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
    nvim +PlugInstall +qall
    nvim +PlugUpdate +qall
    antigen update

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
