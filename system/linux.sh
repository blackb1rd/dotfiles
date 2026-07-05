#!/bin/sh
# Ubuntu / GNOME system defaults for a developer machine — the Linux counterpart
# of system/macos.sh. Idempotent and safe to re-run.
#
# Two parts:
#   1. User-level GNOME desktop tweaks via gsettings (no sudo).
#   2. Optional system-level dev limits via sudo (inotify watches, open files,
#      processes) — the Linux parallel to the macOS launchd/ limit daemons.
#
#   ./system/linux.sh
case "$(uname)" in Linux) ;; *) echo "linux.sh: not Linux, skipping."; exit 0 ;; esac

set -u

# --------------------------------------------------------------------------
# 1. GNOME desktop (gsettings). gset() only writes a key that actually exists
#    in the running GNOME, so this stays safe across versions / non-GNOME.
# --------------------------------------------------------------------------
if command -v gsettings >/dev/null 2>&1; then
  gset() {
    _s=$1 _k=$2 _v=$3
    gsettings list-schemas 2>/dev/null | grep -qx "$_s" || return 0
    gsettings list-keys "$_s" 2>/dev/null | grep -qx "$_k" || return 0
    gsettings set "$_s" "$_k" "$_v"
  }

  # Keyboard: fast repeat (parallels macOS KeyRepeat/InitialKeyRepeat)
  gset org.gnome.desktop.peripherals.keyboard repeat-interval "uint32 20"
  gset org.gnome.desktop.peripherals.keyboard delay "uint32 200"

  # Touchpad: tap to click
  gset org.gnome.desktop.peripherals.touchpad tap-to-click true

  # Files: show hidden entries (Nautilus + GTK file chooser)
  gset org.gnome.nautilus.preferences default-folder-viewer "'list-view'"
  gset org.gtk.Settings.FileChooser show-hidden true
  gset org.gtk.gtk4.Settings.FileChooser show-hidden true

  # Interface: dark theme, battery %, weekday+date in clock
  gset org.gnome.desktop.interface color-scheme "'prefer-dark'"
  gset org.gnome.desktop.interface show-battery-percentage true
  gset org.gnome.desktop.interface clock-show-weekday true
  gset org.gnome.desktop.interface clock-show-date true

  # Window buttons: minimize + maximize + close (dev-friendly)
  gset org.gnome.desktop.wm.preferences button-layout "'appmenu:minimize,maximize,close'"

  # Don't sleep on AC power while plugged in at the desk
  gset org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type "'nothing'"

  # Ubuntu dock: click a running app's icon to minimize it
  gset org.gnome.shell.extensions.dash-to-dock click-action "'minimize'"

  echo "linux.sh: GNOME gsettings applied."
else
  echo "linux.sh: gsettings not found — skipping GNOME desktop tweaks."
fi

# --------------------------------------------------------------------------
# 2. System-level dev limits (needs sudo). Big file-watcher trees (webpack,
#    vite, VS Code, jest --watch) exhaust the default inotify watch limit and
#    fail with ENOSPC; heavy dev also hits low nofile/nproc. Raise them
#    persistently. Skipped automatically if sudo isn't available.
# --------------------------------------------------------------------------
if command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
  printf '%s\n' \
    '# dotfiles: developer machine tuning' \
    'fs.inotify.max_user_watches = 524288' \
    'fs.inotify.max_user_instances = 1024' \
    | sudo tee /etc/sysctl.d/99-dotfiles-dev.conf >/dev/null
  sudo sysctl --quiet -p /etc/sysctl.d/99-dotfiles-dev.conf 2>/dev/null || true

  printf '%s\n' \
    '# dotfiles: raise open-file and process limits for interactive users' \
    '*  soft  nofile  1048576' \
    '*  hard  nofile  1048576' \
    '*  soft  nproc   65536' \
    '*  hard  nproc   65536' \
    | sudo tee /etc/security/limits.d/99-dotfiles-dev.conf >/dev/null

  echo "linux.sh: system limits written (inotify + nofile/nproc). Re-login for limits.d."
else
  echo "linux.sh: no passwordless sudo — skipped system limits."
  echo "          run with sudo available to raise inotify/nofile/nproc."
fi
