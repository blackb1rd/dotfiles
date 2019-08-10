[![CircleCI](https://circleci.com/gh/blackb1rd/dotfiles.svg?style=svg)](https://circleci.com/gh/blackb1rd/dotfiles)

# blackb1rd's dotfiles

My comprehensive repository of configured software.  After deployed, it
should Just Work™ with both ``startx``.

Vim bundles are included through submodules. Make sure to:

```
git submodule update --init --recursive
```

Do the setup dotfiles.
```shell
./setup.sh --os linux
```

For the update git all submodules after do the setup:
```
git subpull
```

Some details on the more highly customized programs:

|                 | Description                                       |
| --------------- | :------------------------------------------------ |
| **X**           | Xresource, xinitrc, and gtk settings              |
| **mutt**        | Mutt to access gmail                              |
| **ncmpcpp**     | Music and media library management                |
| **tmux**        | Terminal multiplexer config                       |
| **[vim]**       | My vim and gvim config and all the bundles I use. |
| **shell**       | My each of shell config                                     |

  [vim]: https://github.com/blackb1rd/dotfiles/blob/master/vim/README.md
