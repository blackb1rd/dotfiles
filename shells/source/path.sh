#!/bin/sh

AddCurrentUserPath() {
  # Add Path
  pathadd "/sbin"
  pathadd "/snap/bin"
  pathadd "$HOME/.go/bin/"
  export ANDROID_HOME=$HOME/Android/Sdk
  pathadd "$ANDROID_HOME/emulator"
  pathadd "$ANDROID_HOME/tools"
  pathadd "$ANDROID_HOME/tools/bin"
  pathadd "$ANDROID_HOME/platform-tools"
  pathadd "$(yarn global bin)"
  pathadd "/usr/lib/dart/bin"
  pathadd "$HOME/development/flutter/bin"

  case $(uname) in
    CYGWIN_NT-* | MSYS_NT-* )
      export EDITOR=vim
      pathadd "/mingw64/bin"
      export GOROOT=/mingw64/lib/go
      export GOPATH=/mingw64
      ;;
    * )

      if [ -d "$HOME/.pyenv" ] ; then
        export PYENV_ROOT=$HOME/.pyenv
        if [ -d "$PYENV_ROOT/bin" ] ; then
          pathadd "$PYENV_ROOT/bin"
        else
          pathadd "$PYENV_ROOT/shims"
        fi
        if command -v pyenv > /dev/null 2>&1; then
          eval "$(pyenv init - --no-rehash)"
          eval "$(pyenv virtualenv-init -)"
        fi
        pyenv activate py3nvim 2> /dev/null
        if [ -n "$VIRTUAL_ENV" ] && [ -e "${VIRTUAL_ENV}/bin/activate" ]; then
          # shellcheck disable=SC1090
          . "${VIRTUAL_ENV}/bin/activate"
        fi
      fi

      if [ -d "$HOME/.rbenv" ] ; then
        pathadd "$HOME/.rbenv/bin"
        eval "$(rbenv init -)"
      fi

      if [ -d "$HOME/.rustup" ] ; then
        export RUSTUP_HOME=$HOME/.rustup
      fi

      export PYTHONSTARTUP=$HOME/.pythonrc
      if [ -x "$(command -v nvim)" ] ; then
        export EDITOR=nvim
        alias vim="nvim"
        alias vimdiff='nvim -d'
      else
        export EDITOR=vim
      fi

      if [ -d "$HOME/.go" ] ; then
        export GOPATH=$HOME/.go
      elif [ -d "$HOME/go" ] ; then
        export GOPATH=$HOME/go
      fi

      if [ -d "/usr/local/go/bin" ] ; then
        pathadd "/usr/local/go/bin"
      elif [ -f "/etc/os-release" ] ; then
        os_release_id="$(grep -E '^ID=([a-zA-Z]*)' /etc/os-release | cut -d '=' -f 2)"
        os_version_id="$(grep -E '^VERSION_ID="([0-9\.]*)"' /etc/os-release | cut -d '=' -f 2 | tr -d '"')"
        case "$os_release_id" in
          "ubuntu")
            case "$os_version_id" in
              "16.04" | "18.04" | "18.10")
                export GOROOT=/usr/lib/go-1.14/
                pathadd "/usr/lib/go-1.14/bin"
              ;;
              *)
                export GOROOT=/usr/lib/go/
                pathadd "/usr/lib/go/bin"
              ;;
            esac
            ;;
          "debian")
            if [ -d "/usr/local/go" ] ; then
              export GOROOT=/usr/local/go/
              pathadd "/usr/local/go/bin"
            fi
        esac
      fi
      ;;
  esac
}
