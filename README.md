# dotfiles

Personal dotfiles — **zsh + [Powerlevel10k](https://github.com/romkatv/powerlevel10k) + [Catppuccin](https://catppuccin.com) Mocha**, with Claude Code set to follow the terminal palette.

Designed to work with [Coder](https://coder.com)'s `dotfiles` module (which runs `install.sh` automatically after cloning), and to run standalone.

## Install

```sh
git clone https://github.com/chrismegyeri/coder_dotfiles.git ~/coder_dotfiles
~/coder_dotfiles/install.sh
```

Or in Coder: set the workspace's **Dotfiles URL** to `https://github.com/chrismegyeri/coder_dotfiles.git`.

## What it does

- Installs `zsh` and clones Powerlevel10k + `zsh-autosuggestions` + `zsh-syntax-highlighting` into `~/.local/share/zsh`.
- Applies the **Catppuccin Mocha** syntax-highlighting theme and P10k accent colours.
- Symlinks `.zshrc` and `.p10k.zsh` into `$HOME` (backing up any existing files).
- Sets `zsh` as the default shell.
- Writes `~/.claude/settings.json` with `theme: dark-ansi` so Claude Code renders in the Catppuccin terminal palette.

## Fonts (fixing the "boxes" in the prompt)

Powerlevel10k icons need a **Nerd Font** wherever the terminal is *drawn*:

- **Browser terminal** (code-server / Coder web terminal): the font must be on
  **your local machine**. Install **MesloLGS NF** (the 4 files below) on your OS,
  then in code-server set `terminal.integrated.fontFamily` to `MesloLGS NF`
  (already set by the template) — refresh the terminal.
- **`coder ssh` in your own terminal app**: install the font locally and select
  it in that app's settings.
- **KasmVNC desktop** (rendered server-side): `install.sh` already drops the font
  into `~/.local/share/fonts`, so it works there.

Download MesloLGS NF:
<https://github.com/romkatv/powerlevel10k/blob/master/font.md> — or the 4 TTFs
from `github.com/romkatv/powerlevel10k-media`.

Don't want to install a font? Run `p10k configure` and choose the ASCII/no-icon
option, or remove `POWERLEVEL9K_MODE=nerdfont-complete` from `.p10k.zsh`.

## Making Claude Code (and the terminal) Catppuccin

Claude Code has **no native Catppuccin theme**; its `dark-ansi` theme (set here)
follows the **terminal's 16-colour ANSI palette**. So Claude looks Catppuccin
only when the terminal's palette is Catppuccin:

- **code-server terminal**: the Catppuccin Mocha VS Code theme (installed by the
  template) sets the integrated terminal's ANSI colours → Claude is Catppuccin
  there automatically.
- **Coder web terminal / external terminal**: set that terminal's colour scheme
  to **Catppuccin Mocha** (most terminals have a Catppuccin theme). Then Claude
  follows it.

Tip: run `claude` from inside the **code-server integrated terminal** to get the
Catppuccin look without extra setup.
