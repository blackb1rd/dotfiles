#!/bin/sh

# ---------------------------------------------------------------------------
# Shared environment for every shell that sources this file (bash, zsh, ...).
# Centralised here so the individual rc files (bashrc/zshrc) don't repeat it.
# ---------------------------------------------------------------------------
export FLUTTER_GIT_URL="ssh://git@github.com/flutter/flutter.git"
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# Prepend personal bin dirs once (idempotent -> no PATH bloat on nested shells);
# ~/.cabal/bin is appended as a fallback.
for _dir in "$HOME/bin" "$HOME/.local/bin" ; do
  [ -d "$_dir" ] || continue
  case ":$PATH:" in
    *":$_dir:"*) ;;
    *) PATH="$_dir:$PATH" ;;
  esac
done
if [ -d "$HOME/.cabal/bin" ] ; then
  case ":$PATH:" in
    *":$HOME/.cabal/bin:"*) ;;
    *) PATH="$PATH:$HOME/.cabal/bin" ;;
  esac
fi
unset _dir
export PATH

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

      # pyenv: put bin + shims on PATH now (so python/pip resolve), but DEFER the
      # costly `pyenv init` (shell function, rehash, completion, ~75ms) to the
      # first `pyenv` call via a lazy shim function. (The old `pyenv activate
      # py3nvim` was already a no-op — that virtualenv does not exist — so it is
      # dropped.) Shims are prepended so pyenv versions take precedence.
      : "${PYENV_ROOT:=$HOME/.pyenv}"
      if [ -d "$PYENV_ROOT" ] ; then
        [ -d "$PYENV_ROOT/bin" ]   && case ":$PATH:" in *":$PYENV_ROOT/bin:"*)   ;; *) PATH="$PYENV_ROOT/bin:$PATH"   ;; esac
        [ -d "$PYENV_ROOT/shims" ] && case ":$PATH:" in *":$PYENV_ROOT/shims:"*) ;; *) PATH="$PYENV_ROOT/shims:$PATH" ;; esac
        if command -v pyenv > /dev/null 2>&1 ; then
          # self-replacing lazy shim; body runs on first call (SC2317/SC2329 false positive)
          # shellcheck disable=SC2317,SC2329
          pyenv() {
            unset -f pyenv
            eval "$(command pyenv init - 2>/dev/null)"
            command pyenv commands 2>/dev/null | grep -qx virtualenv-init \
              && eval "$(command pyenv virtualenv-init - 2>/dev/null)"
            pyenv "$@"
          }
        fi
      fi

      # rbenv: same lazy treatment — its init is the single biggest cost (~140ms).
      if [ -d "$HOME/.rbenv" ] ; then
        [ -d "$HOME/.rbenv/bin" ]   && case ":$PATH:" in *":$HOME/.rbenv/bin:"*)   ;; *) PATH="$HOME/.rbenv/bin:$PATH"   ;; esac
        [ -d "$HOME/.rbenv/shims" ] && case ":$PATH:" in *":$HOME/.rbenv/shims:"*) ;; *) PATH="$HOME/.rbenv/shims:$PATH" ;; esac
        if command -v rbenv > /dev/null 2>&1 ; then
          # self-replacing lazy shim; body runs on first call (SC2317/SC2329 false positive)
          # shellcheck disable=SC2317,SC2329
          rbenv() { unset -f rbenv; eval "$(command rbenv init - 2>/dev/null)"; rbenv "$@"; }
        fi
      fi
      export PATH

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
