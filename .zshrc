# If this terminal's terminfo isn't known to the host (common over SSH from
# kitty/alacritty/foot/wezterm/ghostty), fall back to xterm-256color so the zsh
# line editor positions the cursor correctly. Without this, keystrokes and the
# autosuggestion ghost text can duplicate/garble on redraw. Must run early.
if [[ -n "${TERM:-}" ]] && ! infocmp "$TERM" >/dev/null 2>&1; then
  export TERM=xterm-256color
fi

# Powerlevel10k instant prompt (keep near the top).
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export PATH="$HOME/.local/bin:$PATH"
ZDIR="$HOME/.local/share/zsh"

# --- Catppuccin Mocha terminal palette (OSC escapes) ------------------------
# Repaints the terminal's 16 ANSI colours + fg/bg/cursor to Catppuccin Mocha,
# so fastfetch, Claude Code (dark-ansi) and anything using ANSI colours look
# Catppuccin even in terminals without a Catppuccin theme (e.g. the Coder web
# terminal). Works in xterm.js / xterm-compatible terminals. Interactive TTYs only.
if [[ -o interactive && -t 1 && "$TERM" != "linux" && "$TERM" != "dumb" ]]; then
  typeset -A _catp=(
    0  45475a  1  f38ba8  2  a6e3a1  3  f9e2af  4  89b4fa  5  f5c2e7  6  94e2d5  7  bac2de
    8  585b70  9  f38ba8  10 a6e3a1  11 f9e2af  12 89b4fa  13 f5c2e7  14 94e2d5  15 a6adc8
  )
  for _i in {0..15}; do printf '\e]4;%d;#%s\e\\' "$_i" "${_catp[$_i]}"; done
  printf '\e]10;#cdd6f4\e\\'   # foreground (Text)
  printf '\e]11;#1e1e2e\e\\'   # background (Base)
  printf '\e]12;#f5e0dc\e\\'   # cursor (Rosewater)
  unset _catp _i
fi

# --- Prompt -----------------------------------------------------------------
# Default: Powerlevel10k. oh-my-posh is also installed; to use it instead,
# comment the two P10k lines and uncomment the oh-my-posh block.
source "$ZDIR/powerlevel10k/powerlevel10k.zsh-theme"
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# if command -v oh-my-posh >/dev/null 2>&1; then
#   eval "$(oh-my-posh init zsh --config "$HOME/.cache/oh-my-posh/themes/catppuccin_mocha.omp.json")"
# fi

# --- Plugins (order matters) ------------------------------------------------
# autosuggestions first; syntax-highlighting must be sourced LAST of the
# plugins; the Catppuccin highlight styles go AFTER the plugin (per Catppuccin).
source "$ZDIR/zsh-autosuggestions/zsh-autosuggestions.zsh" 2>/dev/null
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=245'

source "$ZDIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" 2>/dev/null
[[ -f "$ZDIR/catppuccin_mocha.zsh" ]] && source "$ZDIR/catppuccin_mocha.zsh"

# --- History + QoL ----------------------------------------------------------
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt share_history hist_ignore_dups hist_ignore_space
export EDITOR=vi
alias ll='ls -alh'
alias la='ls -A'
[ -d ~/Projects/secure-ai-cyberrange ] && alias cdp='cd ~/Projects/secure-ai-cyberrange'
