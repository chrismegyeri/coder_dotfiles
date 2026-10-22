# dotfiles

Personal dotfiles — **zsh + [Powerlevel10k](https://github.com/romkatv/powerlevel10k) + [Catppuccin](https://catppuccin.com) Mocha**, with Claude Code set to follow the terminal palette.

Designed to work with [Coder](https://coder.com)'s `dotfiles` module (which runs `install.sh` automatically after cloning), and to run standalone.

## Install

```sh
git clone https://github.com/chrismegyeri/dotfiles.git ~/dotfiles
~/dotfiles/install.sh
```

Or in Coder: set the workspace's **Dotfiles URL** to `https://github.com/chrismegyeri/dotfiles.git`.

## What it does

- Installs `zsh` and clones Powerlevel10k + `zsh-autosuggestions` + `zsh-syntax-highlighting` into `~/.local/share/zsh`.
- Applies the **Catppuccin Mocha** syntax-highlighting theme and P10k accent colours.
- Symlinks `.zshrc` and `.p10k.zsh` into `$HOME` (backing up any existing files).
- Sets `zsh` as the default shell.
- Writes `~/.claude/settings.json` with `theme: dark-ansi` so Claude Code renders in the Catppuccin terminal palette.

## Fonts

Powerlevel10k expects a **Nerd Font** (e.g. `MesloLGS NF`) in your terminal. Install one locally if glyphs look wrong.
