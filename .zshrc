# Powerlevel10k instant prompt (keep near the top).
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export PATH="$HOME/.local/bin:$PATH"
ZDIR="$HOME/.local/share/zsh"

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
