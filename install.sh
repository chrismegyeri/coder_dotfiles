#!/usr/bin/env bash
# Dotfiles installer. Coder's dotfiles module runs this automatically after
# cloning the repo; it's also safe to run by hand: `./install.sh`.
#
# Installs zsh + Powerlevel10k + Catppuccin Mocha, links the shell configs, and
# points Claude Code at its ANSI theme (so it follows the Catppuccin terminal).
set -eu

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# zsh (sudo is available in Coder's base images; skip quietly if not root-capable)
if ! command -v zsh >/dev/null 2>&1; then
  if command -v sudo >/dev/null 2>&1; then
    sudo DEBIAN_FRONTEND=noninteractive apt-get update -qq \
      && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq zsh fonts-powerline unzip || true
  fi
fi

ZDIR="$HOME/.local/share/zsh"
mkdir -p "$ZDIR"
clone() { [ -d "$2" ] || git clone --depth=1 "$1" "$2" >/dev/null 2>&1 || true; }
clone https://github.com/romkatv/powerlevel10k.git              "$ZDIR/powerlevel10k"
clone https://github.com/zsh-users/zsh-autosuggestions.git      "$ZDIR/zsh-autosuggestions"
clone https://github.com/zsh-users/zsh-syntax-highlighting.git  "$ZDIR/zsh-syntax-highlighting"
clone https://github.com/catppuccin/zsh-syntax-highlighting.git "$ZDIR/catppuccin-zsh-syntax-highlighting"
cp "$ZDIR/catppuccin-zsh-syntax-highlighting/themes/catppuccin_mocha-zsh-syntax-highlighting.zsh" \
   "$ZDIR/catppuccin_mocha.zsh" 2>/dev/null || true

# Link shell configs (back up anything already there).
link() {
  local src="$1" dst="$2"
  [ -e "$dst" ] && [ ! -L "$dst" ] && mv "$dst" "$dst.bak.$(date +%s)" || true
  ln -sfn "$src" "$dst"
}
link "$DOTFILES_DIR/.zshrc"  "$HOME/.zshrc"
link "$DOTFILES_DIR/.p10k.zsh" "$HOME/.p10k.zsh"

# Default shell -> zsh (persists in the home volume).
if command -v zsh >/dev/null 2>&1 && command -v sudo >/dev/null 2>&1; then
  sudo chsh -s "$(command -v zsh)" "$(whoami)" 2>/dev/null || true
fi

# Claude Code: dark-ansi theme follows the Catppuccin terminal palette.
mkdir -p "$HOME/.claude"
if [ ! -f "$HOME/.claude/settings.json" ]; then
  printf '{\n  "theme": "dark-ansi"\n}\n' > "$HOME/.claude/settings.json"
fi

echo "dotfiles installed: zsh + Powerlevel10k + Catppuccin Mocha; Claude theme=dark-ansi"
