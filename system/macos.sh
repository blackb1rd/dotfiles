#!/bin/sh
# macOS system defaults for a developer machine.
#
# Idempotent and safe to re-run. Review before running — these are opinionated;
# comment out anything you dislike. Some changes need a logout/restart to fully
# apply. Runs at user level (no sudo). Counterpart: system/linux.sh (GNOME).
#
#   ./system/macos.sh
[ "$(uname)" = "Darwin" ] || { echo "macos.sh: not macOS, skipping."; exit 0; }

set -u

# --- Keyboard: fast key repeat, and let editors (VS Code, etc.) repeat keys ---
defaults write -g KeyRepeat -int 2               # fastest sane repeat rate
defaults write -g InitialKeyRepeat -int 15       # short delay before repeat
defaults write -g ApplePressAndHoldEnabled -bool false   # repeat instead of accent popup

# --- Typing: stop macOS "fixing" code as you write it ---
defaults write -g NSAutomaticSpellingCorrectionEnabled -bool false
defaults write -g NSAutomaticCapitalizationEnabled -bool false
defaults write -g NSAutomaticPeriodSubstitutionEnabled -bool false
defaults write -g NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write -g NSAutomaticDashSubstitutionEnabled -bool false

# --- Trackpad: tap to click ---
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write -g com.apple.mouse.tapBehavior -int 1

# --- Finder: show everything, path/status bars, list view, POSIX title ---
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"   # list view
defaults write com.apple.finder _FXSortFoldersFirst -bool true
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"   # search current folder
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# --- No .DS_Store on network/USB volumes ---
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# --- Screenshots: PNG, no window shadow, into ~/Screenshots ---
mkdir -p "$HOME/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Screenshots"
defaults write com.apple.screencapture type -string "png"
defaults write com.apple.screencapture disable-shadow -bool true

# --- Dialogs / documents: expand panels, save to disk not iCloud ---
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# --- Dock: fast autohide, don't reshuffle Spaces, minimize into app icon ---
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock mru-spaces -bool false
defaults write com.apple.dock minimize-to-application -bool true

# --- Don't nag when opening downloaded apps ---
defaults write com.apple.LaunchServices LSQuarantine -bool false

echo "macos.sh: applied. Restarting Finder, Dock, SystemUIServer..."
killall Finder Dock SystemUIServer 2>/dev/null || true
echo "Some settings (keyboard) take effect after a logout/restart."
