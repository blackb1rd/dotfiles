#!/bin/sh

path_prepend() {
  [ -n "$1" ] || return 0
  case ":${PATH}:" in
    *":$1:"*) ;;
    *) PATH="$1${PATH:+:$PATH}" ;;
  esac
}

path_append() {
  [ -n "$1" ] || return 0
  case ":${PATH}:" in
    *":$1:"*) ;;
    *) PATH="${PATH:+$PATH:}$1" ;;
  esac
}

# Single source of truth: all static environment variables (including PATH) are
# defined in *.conf files under environment.d, which are also read directly by
# systemd (and therefore VS Code) on systemd-based systems. The conf file uses
# KEY=${VAR}/path syntax, which is valid POSIX sh — so we can source them here.
# Guard the directory: zsh aborts on a glob that matches nothing, and the
# directory may not exist at all.
if [ -d "${HOME}/.config/environment.d" ]; then
  for _env_conf in "${HOME}/.config/environment.d/"*.conf; do
    # shellcheck disable=SC1090
    [ -f "$_env_conf" ] && set -a && . "$_env_conf" && set +a
  done
  unset _env_conf
fi

# Deduplicate PATH entries (handles re-sourcing this file in subshells)
_dedup_path=""
_old_IFS="$IFS"; IFS=:
for _dir in $PATH; do
  case ":${_dedup_path}:" in
    *":${_dir}:"*) ;;
    *) _dedup_path="${_dedup_path:+${_dedup_path}:}${_dir}" ;;
  esac
done
IFS="$_old_IFS"
PATH="$_dedup_path"
unset _dedup_path _old_IFS _dir

# GPG_TTY: gpg hands this to pinentry so it knows which terminal to prompt on.
# Without it, signing fails with "Inappropriate ioctl for device" / "gpg failed
# to sign the data" -- most often inside tmux, where the agent outlives the
# terminal that started it. It cannot live in environment.d/*.conf like the
# static vars above: systemd .conf files take literal values, and this one
# differs per terminal.
#
# Guarded on stdin being a terminal because .zshenv sources this file for every
# zsh, including non-interactive ones, where `tty` prints "not a tty".
if [ -t 0 ] ; then
  GPG_TTY="$(tty)"
  export GPG_TTY
fi
