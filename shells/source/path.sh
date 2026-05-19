#!/bin/sh

AddCurrentUserPath() {
  # Static paths/vars are already set via environment.d/env.conf (sourced by
  # environment.sh and read directly by systemd). Only dynamic/conditional
  # logic that requires a running shell belongs here.

  # yarn global bin (runtime command)
  if [ -x "$(command -v yarn)" ] ; then
    pathadd "$(yarn global bin)"
  fi

  case $(uname) in
    CYGWIN_NT-* | MSYS_NT-* )
      export ANDROID_HOME="$HOME/Android/Sdk"
      export EDITOR=vim
      pathadd "/mingw64/bin"
      export GOROOT=/mingw64/lib/go
      export GOPATH=/mingw64
      ;;
    * )
      # Darwin uses a different Android SDK path than env.conf default
      case $(uname) in
        Darwin* )
          export ANDROID_HOME="$HOME/Library/Android/sdk"
          ;;
      esac

      # pyenv: init hooks must be eval'd in the shell
      if [ -d "$HOME/.pyenv" ] ; then
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

      # rbenv: init hook must be eval'd in the shell
      if [ -d "$HOME/.rbenv" ] ; then
        eval "$(rbenv init -)"
      fi

      # nvim aliases (shell-only)
      if [ -x "$(command -v nvim)" ] ; then
        alias vim="nvim"
        alias vimdiff='nvim -d'
      fi

      # Go: detect installation path if not already set by env.conf
      if [ -z "$GOROOT" ] ; then
        if [ -d "/usr/local/go/bin" ] ; then
          export GOROOT=/usr/local/go
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
                  export GOROOT=/snap/go/current
                  pathadd "$HOME/go/bin"
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
      fi
      ;;
  esac
}
