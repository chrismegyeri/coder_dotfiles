#!/usr/bin/env bash
# Dotfiles installer. Coder's dotfiles module runs this automatically after
# cloning the repo; it's also safe to run by hand: `./install.sh`.
#
# Installs zsh + Powerlevel10k + Catppuccin Mocha, links the shell configs, and
# points Claude Code at its ANSI theme (so it follows the Catppuccin terminal).
set -eu

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# Base deps (sudo is available in Coder's base images; install only what's missing).
# jq is needed by the Claude Code statusline; git/unzip by the rest.
_need=""
for _b in zsh jq git unzip tmux fzf; do command -v "$_b" >/dev/null 2>&1 || _need="$_need $_b"; done
if [ -n "$_need" ] && command -v sudo >/dev/null 2>&1; then
  _apt() { sudo DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Lock::Timeout=300 "$@"; }
  _apt update -qq || true
  _apt install -y -qq $_need fonts-powerline || true
  # Optional extras, installed one by one so a missing package can't abort the rest.
  for _x in zoxide eza bat stow; do command -v "$_x" >/dev/null 2>&1 || _apt install -y -qq "$_x" >/dev/null 2>&1 || true; done
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

# MesloLGS NF (the recommended Nerd Font for Powerlevel10k glyphs). This helps
# server-rendered terminals (e.g. KasmVNC). Browser terminals (code-server /
# Coder web) render with the client's fonts, so install this font on your LOCAL
# machine too and select it there -- see README.
FONTDIR="$HOME/.local/share/fonts"
mkdir -p "$FONTDIR"
_fbase="https://github.com/romkatv/powerlevel10k-media/raw/master"
for f in "MesloLGS NF Regular.ttf" "MesloLGS NF Bold.ttf" "MesloLGS NF Italic.ttf" "MesloLGS NF Bold Italic.ttf"; do
  [ -f "$FONTDIR/$f" ] || curl -fsSL "$_fbase/${f// /%20}" -o "$FONTDIR/$f" 2>/dev/null || true
done
command -v fc-cache >/dev/null 2>&1 && fc-cache -f "$FONTDIR" >/dev/null 2>&1 || true

# oh-my-posh (prompt engine) — installed and available alongside Powerlevel10k.
# Installs the binary into ~/.local/bin and its themes (incl. catppuccin_mocha)
# into ~/.cache/oh-my-posh/themes. P10k stays the active prompt; see .zshrc.
mkdir -p "$HOME/.local/bin"
if ! command -v oh-my-posh >/dev/null 2>&1 && [ ! -x "$HOME/.local/bin/oh-my-posh" ]; then
  curl -fsSL https://ohmyposh.dev/install.sh | bash -s -- -d "$HOME/.local/bin" >/dev/null 2>&1 || \
    echo "oh-my-posh install skipped (network?)"
fi

# Link shell configs (back up anything already there).
link() {
  local src="$1" dst="$2"
  [ -e "$dst" ] && [ ! -L "$dst" ] && mv "$dst" "$dst.bak.$(date +%s)" || true
  ln -sfn "$src" "$dst"
}
link "$DOTFILES_DIR/.zshrc"  "$HOME/.zshrc"
link "$DOTFILES_DIR/.p10k.zsh" "$HOME/.p10k.zsh"

# tmux (Catppuccin Mocha, persistent sessions) + popup helpers.
mkdir -p "$HOME/.config/tmux" "$HOME/.local/bin"
link "$DOTFILES_DIR/tmux/tmux.conf"   "$HOME/.config/tmux/tmux.conf"
link "$DOTFILES_DIR/bin/tmux-keys"     "$HOME/.local/bin/tmux-keys"
link "$DOTFILES_DIR/bin/tmux-sessions" "$HOME/.local/bin/tmux-sessions"
chmod +x "$DOTFILES_DIR"/bin/tmux-*

# --- OpenCode ----------------------------------------------------------------
# Themes: Catppuccin Mocha, all accents (catppuccin/opencode). Mocha/mauve is the
# default, seeded below; switch any time with OpenCode's `/theme`.
OC="$HOME/.config/opencode"
mkdir -p "$OC/themes"
cp -f "$DOTFILES_DIR"/opencode/themes/*.json "$OC/themes/"
cp -f "$DOTFILES_DIR"/opencode/oh-my-opencode.jsonc.example "$OC/"

# tui.json holds the theme (opencode.json has no `theme` key any more). Seeded
# once only, so a theme picked with `/theme` isn't reset on the next start.
[ -f "$OC/tui.json" ] || cp "$DOTFILES_DIR/opencode/tui.json" "$OC/tui.json"

# opencode.json: oh-my-opencode as the base agent harness (OpenCode installs the
# npm plugin itself at startup), plus Ollama as a provider when OLLAMA_HOST is set.
# MERGED, never overwritten -- Coder's opencode module writes `.mcp.coder` into
# this same file, and hand-added keys must survive an install.sh re-run.
# NO CREDENTIALS ARE WRITTEN HERE: keys are referenced as {env:VAR} and resolved
# from the environment at runtime (in a Coder workspace: ~/.config/coder/secrets.env,
# populated from template variables). Never commit a literal token to this repo.
if command -v jq >/dev/null 2>&1; then
  [ -s "$OC/opencode.json" ] || echo '{}' > "$OC/opencode.json"
  _tmp="$(mktemp)"

  # Base keys. The plugin list is unioned, so a plugin added by hand is kept.
  jq -s '.[0] as $cur | .[1] as $base
         | ($cur * $base)
         | .plugin = ((($cur.plugin // []) + ($base.plugin // [])) | unique)' \
    "$OC/opencode.json" "$DOTFILES_DIR/opencode/opencode.json" > "$_tmp" \
    && mv "$_tmp" "$OC/opencode.json"

  # Ollama. A custom provider must enumerate its models, so ask the server what
  # it has; without an endpoint the provider is removed again.
  if [ -n "${OLLAMA_HOST:-}" ]; then
    _models='{}'
    if _tags="$(curl -fsS --max-time 5 \
          ${OLLAMA_TOKEN:+-H "Authorization: Bearer $OLLAMA_TOKEN"} \
          "$OLLAMA_HOST/api/tags" 2>/dev/null)"; then
      _models="$(printf '%s' "$_tags" |
        jq '[.models[]? | {key: .name, value: {name: .name}}] | from_entries')"
      echo "opencode: discovered $(printf '%s' "$_models" | jq 'length') Ollama model(s)"
    else
      echo "opencode: $OLLAMA_HOST unreachable -- Ollama provider left with no models"
    fi
    _tmp="$(mktemp)"
    jq -s --argjson models "$_models" \
      '(.[0] * .[1])
       | .provider.ollama.models = $models
       | if (env.OLLAMA_TOKEN // "") == "" then del(.provider.ollama.options.apiKey) else . end' \
      "$OC/opencode.json" "$DOTFILES_DIR/opencode/ollama-provider.json" > "$_tmp" \
      && mv "$_tmp" "$OC/opencode.json"
  else
    _tmp="$(mktemp)"
    jq 'del(.provider.ollama)
        | if (.provider // {} | length) == 0 then del(.provider) else . end' \
      "$OC/opencode.json" > "$_tmp" && mv "$_tmp" "$OC/opencode.json"
  fi
  echo "opencode: oh-my-opencode plugin + Catppuccin Mocha (mauve) configured"
else
  echo "opencode: jq missing -- skipped opencode.json" >&2
fi

TPM="$HOME/.local/share/tmux/plugins/tpm"
mkdir -p "$(dirname "$TPM")"
clone https://github.com/tmux-plugins/tpm.git "$TPM"
[ -x "$TPM/bin/install_plugins" ] && \
  TMUX_PLUGIN_MANAGER_PATH="$HOME/.local/share/tmux/plugins" "$TPM/bin/install_plugins" >/dev/null 2>&1 || true

# Default shell -> zsh (persists in the home volume).
if command -v zsh >/dev/null 2>&1 && command -v sudo >/dev/null 2>&1; then
  sudo chsh -s "$(command -v zsh)" "$(whoami)" 2>/dev/null || true
fi

# Claude Code: Catppuccin powerline statusline + dark-ansi theme (follows the
# Catppuccin terminal palette). Merge into settings.json, keeping any existing keys.
mkdir -p "$HOME/.claude"
install -m 0755 "$DOTFILES_DIR/claude/statusline.sh" "$HOME/.claude/statusline.sh"
SETTINGS="$HOME/.claude/settings.json"
[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
if command -v jq >/dev/null 2>&1; then
  _tmp="$(mktemp)"
  jq '. + {
        theme: (.theme // "dark-ansi"),
        statusLine: {type: "command", command: "~/.claude/statusline.sh", padding: 0}
      }' "$SETTINGS" > "$_tmp" && mv "$_tmp" "$SETTINGS"
else
  printf '{\n  "theme": "dark-ansi",\n  "statusLine": { "type": "command", "command": "~/.claude/statusline.sh", "padding": 0 }\n}\n' > "$SETTINGS"
fi

echo "dotfiles installed: zsh + Powerlevel10k + tmux + Catppuccin Mocha; Claude statusline + dark-ansi theme"
