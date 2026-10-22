# Powerlevel10k instant prompt (keep near the top).
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

ZDIR="$HOME/.local/share/zsh"
source "$ZDIR/powerlevel10k/powerlevel10k.zsh-theme"
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# Autosuggestions
source "$ZDIR/zsh-autosuggestions/zsh-autosuggestions.zsh" 2>/dev/null

# Catppuccin Mocha colours for syntax highlighting (load the theme, then the plugin).
[[ -f "$ZDIR/catppuccin_mocha.zsh" ]] && source "$ZDIR/catppuccin_mocha.zsh"
source "$ZDIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" 2>/dev/null

# History + QoL
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt share_history hist_ignore_dups hist_ignore_space
export EDITOR=vi

alias ll='ls -alh'
alias la='ls -A'
[ -d ~/Projects/secure-ai-cyberrange ] && alias cdp='cd ~/Projects/secure-ai-cyberrange'
