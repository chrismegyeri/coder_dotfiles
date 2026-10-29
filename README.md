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

- Installs `zsh` and clones Powerlevel10k + `zsh-autosuggestions` + `zsh-syntax-highlighting` into `~/.local/share/zsh`, sourced in the correct order (autosuggestions → syntax-highlighting → Catppuccin styles).
- Installs **oh-my-posh** (binary + themes) into `~/.local/bin` / `~/.cache/oh-my-posh`, available alongside P10k (P10k is the active prompt; `.zshrc` shows how to switch).
- Applies the **Catppuccin Mocha** syntax-highlighting theme and P10k accent colours.
- Symlinks `.zshrc` and `.p10k.zsh` into `$HOME` (backing up any existing files).
- Installs **tmux** with a Catppuccin Mocha config (`tmux/tmux.conf` -> `~/.config/tmux/`), TPM plugins (catppuccin, resurrect, continuum), and two popup helpers in `~/.local/bin`: `tmux-sessions` (fzf session switcher, `Alt+s`) and `tmux-keys` (searchable cheat sheet, `Alt+/` or `F1`). Prefix is `Ctrl-a`; press `prefix ?` or `Alt+/` for all keys.
- Sets up **OpenCode** (see [OpenCode](#opencode) below): [oh-my-opencode](https://github.com/opensoft/oh-my-opencode) as the base harness, the [Catppuccin](https://github.com/catppuccin/opencode) Mocha themes with **mauve as the default**, and Ollama as a provider when `OLLAMA_HOST` is set.
- Loads secrets from outside the repo: `~/.config/coder/secrets.env` (written by the Coder template) and `~/.zshrc.local` (see `zshrc.local.example`; values are placeholders).
- Sets `zsh` as the default shell.
- Installs a **Catppuccin Mocha powerline statusline** for Claude Code at `~/.claude/statusline.sh` (model / git / context bar / cost / duration / agent / vim segments) and wires it into `settings.json` (`statusLine`). Needs `jq` (installed) + a Nerd Font + a truecolor terminal. Adapted from [tjhanley's gist](https://gist.github.com/tjhanley/01f2d2b682739bdc4802db74655d37c7).
- Writes `~/.claude/settings.json` with `theme: dark-ansi` so Claude Code renders in the Catppuccin terminal palette (merged, keeping any existing keys).

## OpenCode

`install.sh` configures `~/.config/opencode` without ever writing a credential:

- **`opencode.json`** declares the [**oh-my-opencode**](https://github.com/opensoft/oh-my-opencode)
  plugin. OpenCode installs npm plugins itself at startup, so there is no
  installer to run and nothing to keep in sync — launch `opencode` and the
  harness (Sisyphus / Oracle / Explore / Librarian, `ultrawork`, Tab → planner)
  is there. Per-agent model overrides go in `~/.config/opencode/oh-my-opencode.json`;
  a commented example is installed beside it as `oh-my-opencode.jsonc.example`.
- **`tui.json`** sets the theme to **`catppuccin-mocha-mauve`**, from the full set of
  [catppuccin/opencode](https://github.com/catppuccin/opencode) Mocha accents copied
  into `~/.config/opencode/themes`. Seeded **once**, so switching with `/theme`
  sticks across re-runs. To change the default for new workspaces, edit
  `opencode/tui.json` here.
- **Providers.** `openrouter` and `zai-coding-plan` (GLM) are built in and need only
  `OPENROUTER_API_KEY` / `ZHIPU_API_KEY` in the environment. **Ollama** is added as a
  custom OpenAI-compatible provider when `OLLAMA_HOST` is set, and because a custom
  provider has to enumerate its models, `install.sh` discovers them from
  `$OLLAMA_HOST/api/tags`. Re-run `install.sh` after pulling new Ollama models.
  Switch model with `/models`.

The config is **merged**, not overwritten: Coder's OpenCode module writes its own
`.mcp.coder` block into the same file, and anything you add by hand is kept. Keys
are referenced as `{env:VAR}` and resolved at runtime.

## Secrets — never in this repo

This repo is public and gets cloned into every workspace, so it must never hold a
token. Credentials reach a shell from two places outside it:

| Source | Written by | Contents |
|--------|-----------|----------|
| `~/.config/coder/secrets.env` (0600) | the Coder template, at every workspace start, from its template variables | Gitea/Forgejo tokens, Proxmox token ID+secret, NAS host, `OLLAMA_HOST`/`OLLAMA_TOKEN`, `OPENROUTER_API_KEY`, `ZHIPU_API_KEY` |
| `~/.zshrc.local` (untracked) | you, on any machine | anything machine-local; loaded last so it wins |

`.zshrc` sources both. A `.gitignore` covers the usual secret filenames, and
`.githooks/pre-commit` blocks a commit containing anything that looks like a key.
Enable it once per clone:

```sh
git config core.hooksPath .githooks
```

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
