# If this terminal's terminfo isn't known to the host (common over SSH from
# kitty/alacritty/foot/wezterm/ghostty), fall back to xterm-256color so the zsh
# line editor positions the cursor correctly. Without this, keystrokes and the
# autosuggestion ghost text can duplicate/garble on redraw. Must run early.
if [[ -n "${TERM:-}" ]] && ! infocmp "$TERM" >/dev/null 2>&1; then
  export TERM=xterm-256color
fi

# Auto-attach to the persistent tmux session from Ghostty. New Ghostty
# windows/tabs all land in the same "main" session. Set NO_TMUX=1 to skip.
if [[ -o interactive && -z "$TMUX" && -z "$NO_TMUX" && "$TERM_PROGRAM" == "ghostty" ]] \
   && command -v tmux >/dev/null 2>&1; then
  exec tmux new-session -A -s main
fi

# Powerlevel10k instant prompt (keep near the top).
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export PATH="$HOME/.local/bin:$PATH"
ZDIR="$HOME/.local/share/zsh"

# Source the first readable file of the given candidates (user clone first,
# then distro package paths, so this works on Coder/Debian and Arch alike).
_first() { local f; for f in "$@"; do [[ -r $f ]] && { source "$f"; return 0; }; done; return 1; }

# --- Catppuccin Mocha terminal palette (OSC escapes) ------------------------
# Repaints the terminal's 16 ANSI colours + fg/bg/cursor to Catppuccin Mocha,
# so fastfetch, Claude Code (dark-ansi) and anything using ANSI colours look
# Catppuccin even in terminals without a Catppuccin theme (e.g. the Coder web
# terminal). Skipped in Ghostty/tmux, which are themed natively. Interactive TTYs only.
if [[ -o interactive && -t 1 && -z "$TMUX" && "$TERM_PROGRAM" != "ghostty" \
      && "$TERM" != "linux" && "$TERM" != "dumb" ]]; then
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
# Default: Powerlevel10k. oh-my-posh is also installed by the Coder flow; to use
# it instead, comment the two P10k lines and uncomment the oh-my-posh block.
_first "$ZDIR/powerlevel10k/powerlevel10k.zsh-theme" \
       /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# if command -v oh-my-posh >/dev/null 2>&1; then
#   eval "$(oh-my-posh init zsh --config "$HOME/.cache/oh-my-posh/themes/catppuccin_mocha.omp.json")"
# fi

# --- Plugins (order matters) ------------------------------------------------
# autosuggestions first; syntax-highlighting must be sourced LAST of the
# plugins; the Catppuccin highlight styles go AFTER the plugin (per Catppuccin).
_first "$ZDIR/zsh-autosuggestions/zsh-autosuggestions.zsh" \
       /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=245'

_first "$ZDIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" \
       /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
[[ -f "$ZDIR/catppuccin_mocha.zsh" ]] && source "$ZDIR/catppuccin_mocha.zsh"

# --- History + QoL ----------------------------------------------------------
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt share_history hist_ignore_dups hist_ignore_space
export EDITOR=vi
alias ll='ls -alh'
alias la='ls -A'

# --- Optional tools (only wired up when installed) --------------------------
if command -v fzf >/dev/null 2>&1; then
  _first /usr/share/fzf/key-bindings.zsh   # Ctrl-R history, Ctrl-T files, Alt-C cd
  _first /usr/share/fzf/completion.zsh
  export FZF_DEFAULT_OPTS="--height=60% --layout=reverse --border=rounded
    --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8
    --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc
    --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"
fi
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -alh --icons --group-directories-first --git'
  alias la='eza -a --icons --group-directories-first'
fi
command -v bat >/dev/null 2>&1 && export BAT_THEME="Catppuccin Mocha"

# tmux helpers: `ta name` = attach-or-create, `t` = fzf session picker.
ta() { tmux new-session -A -s "${1:-main}"; }
alias t='tmux-sessions'

# Machine-local / secret settings (API tokens etc.). NOT tracked in the repo.
# Copy ~/.dotfiles/zshrc.local.example to ~/.zshrc.local and fill it in. Example:
#   export SOME_SERVICE_API_KEY="<your-api-key>"
[[ -r ~/.zshrc.local ]] && source ~/.zshrc.local
