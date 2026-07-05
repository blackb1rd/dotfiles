# macOS LaunchDaemons

Root-owned daemons that run at boot to raise system-wide limits for a developer
machine. The macOS equivalent of this repo's `systemd/` units.

| Plist | Raises | From → To |
|-------|--------|-----------|
| `limit.maxfiles.plist` | open files (per process) | GUI/launchd soft **256 → 61440** (the kernel cap) |
| `limit.maxproc.plist`  | processes (per user)     | kernel `maxprocperuid` **2666 → maxproc−512** (e.g. 3488). `kern.maxproc` is a fixed system ceiling, not runtime-writable. |

Login shells apply the same file/process soft limits themselves via
`shells/zprofile`; these daemons cover GUI-launched apps (IDEs, Docker Desktop,
browsers) and raise the kernel process ceiling that shells alone cannot.

## Install

`setup.sh --shell` installs them automatically on macOS. Manual install:

```sh
sudo install -o root -g wheel -m 0644 launchd/limit.maxfiles.plist /Library/LaunchDaemons/
sudo install -o root -g wheel -m 0644 launchd/limit.maxproc.plist  /Library/LaunchDaemons/
sudo launchctl load -w /Library/LaunchDaemons/limit.maxfiles.plist
sudo launchctl load -w /Library/LaunchDaemons/limit.maxproc.plist
```

Takes full effect after a reboot (or the `launchctl load` above for the file
limit; the process limit's `sysctl` applies immediately, new logins pick it up).

## Verify

```sh
launchctl limit maxfiles      # -> 61440  ...
launchctl limit maxproc       # -> 3488   4000
sysctl kern.maxprocperuid     # -> 3488
```

## Uninstall

```sh
sudo launchctl unload -w /Library/LaunchDaemons/limit.maxfiles.plist
sudo launchctl unload -w /Library/LaunchDaemons/limit.maxproc.plist
sudo rm /Library/LaunchDaemons/limit.maxfiles.plist /Library/LaunchDaemons/limit.maxproc.plist
```
