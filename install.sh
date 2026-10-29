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

  # `apt-get update` takes /var/lib/apt/lists/lock, which DPkg::Lock::Timeout does
  # NOT cover. In Coder the template's startup script installs packages at the same
  # time as this script, so a single `update` loses the race, leaves the package
  # lists empty, and every install then fails with "Unable to locate package".
  # Retry until the lists are actually usable.
  _updated=""
  for _try in 1 2 3 4 5 6; do
    if _apt update -qq 2>/dev/null && apt-cache policy zsh 2>/dev/null | grep -q 'Candidate:'; then
      _updated=1; break
    fi
    sleep 10
  done
  [ -n "$_updated" ] || echo "warning: apt lists unavailable (lock contention?); skipping apt installs"

  # One package per call, and only if apt actually has a candidate, so one
  # unavailable package can't take the rest of the batch down with it.
  # fonts-powerline is optional: Powerlevel10k's glyphs come from the Nerd Font
  # installed further down, not from this package.
  if [ -n "$_updated" ]; then
    for _p in $_need fonts-powerline zoxide eza bat stow; do
      case "$_p" in zsh|jq|git|unzip|tmux|fzf|fonts-powerline) ;; *)
        command -v "$_p" >/dev/null 2>&1 && continue ;;
      esac
      if apt-cache policy "$_p" 2>/dev/null | grep -q 'Candidate: [^(]'; then
        _apt install -y -qq "$_p" >/dev/null 2>&1 || echo "note: failed to install $_p"
      else
        echo "note: $_p not available on this release, skipped"
      fi
    done
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

# MesloLGS NF (the recommended Nerd Font for Powerlevel10k glyphs). This is what
# actually provides the prompt icons -- the optional fonts-powerline apt package
# only carries the older powerline symbols. It matters for server-rendered
# terminals; browser terminals (code-server / the Coder web terminal) and
# `coder ssh` render with your LOCAL machine's fonts, so install MesloLGS NF
# there too and select it in that client -- see README.
FONTDIR="$HOME/.local/share/fonts"
mkdir -p "$FONTDIR"
_fbase="https://github.com/romkatv/powerlevel10k-media/raw/master"
_fgot=0
for f in "MesloLGS NF Regular.ttf" "MesloLGS NF Bold.ttf" "MesloLGS NF Italic.ttf" "MesloLGS NF Bold Italic.ttf"; do
  if [ -s "$FONTDIR/$f" ]; then _fgot=$((_fgot+1)); continue; fi
  # -f so an HTTP error leaves no truncated file behind; retry a flaky network once.
  if curl -fsSL --retry 2 --retry-delay 2 "$_fbase/${f// /%20}" -o "$FONTDIR/$f" 2>/dev/null \
     && [ -s "$FONTDIR/$f" ]; then
    _fgot=$((_fgot+1))
  else
    rm -f "$FONTDIR/$f"
  fi
done
if [ "$_fgot" -eq 4 ]; then
  echo "fonts: MesloLGS NF installed (4 files) in $FONTDIR"
else
  echo "warning: only $_fgot/4 MesloLGS NF files present -- prompt glyphs may show as boxes"
fi
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

  # Experiential Labs: an OpenAI-compatible gateway, not a models.dev provider,
  # so it needs registering by hand. Set EXPERIENTIALLABS_MODELS (comma
  # separated) to pin specific models; otherwise they're discovered from
  # <base>/models. The gateway fronts ~900 models, so discovery is capped --
  # a model picker with 900 entries is unusable, and OpenCode has to carry
  # every one of them in its config.
  if [ -n "${EXPERIENTIALLABS_TOKEN:-}" ]; then
    : "${EXPERIENTIALLABS_BASE_URL:=https://api.experientiallabs.ai/v1}"
    export EXPERIENTIALLABS_BASE_URL
    _xmodels='{}'
    if [ -n "${EXPERIENTIALLABS_MODELS:-}" ]; then
      _xmodels="$(printf '%s' "$EXPERIENTIALLABS_MODELS" |
        jq -Rr 'split(",") | map(select(length > 0) | {key: ., value: {name: .}}) | from_entries')"
      echo "opencode: Experiential Labs pinned to $(printf '%s' "$_xmodels" | jq 'length') model(s)"
    elif _xlist="$(curl -fsS --max-time 10 -H "Authorization: Bearer $EXPERIENTIALLABS_TOKEN" \
          "$EXPERIENTIALLABS_BASE_URL/models" 2>/dev/null)"; then
      _xmodels="$(printf '%s' "$_xlist" |
        jq '[.data[]? | .id] | sort | .[0:40] | map({key: ., value: {name: .}}) | from_entries')"
      _xtotal="$(printf '%s' "$_xlist" | jq '[.data[]?] | length')"
      echo "opencode: discovered $_xtotal Experiential Labs model(s), exposing $(printf '%s' "$_xmodels" | jq 'length')"
      [ "${_xtotal:-0}" -gt 40 ] 2>/dev/null && \
        echo "  (capped at 40 -- set EXPERIENTIALLABS_MODELS to choose exactly which ones)"
    else
      echo "opencode: $EXPERIENTIALLABS_BASE_URL/models unreachable -- provider added with no models"
      echo "  (set EXPERIENTIALLABS_MODELS to list them explicitly)"
    fi
    _tmp="$(mktemp)"
    jq -s --argjson models "$_xmodels" \
      '(.[0] * .[1]) | .provider.experientiallabs.models = $models' \
      "$OC/opencode.json" "$DOTFILES_DIR/opencode/experientiallabs-provider.json" > "$_tmp" \
      && mv "$_tmp" "$OC/opencode.json"
  else
    _tmp="$(mktemp)"
    jq 'del(.provider.experientiallabs)
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
