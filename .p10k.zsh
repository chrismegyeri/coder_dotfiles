# Compact Powerlevel10k config with Catppuccin Mocha accents.
# The configuration wizard is disabled; run `p10k configure` to regenerate.
typeset -g POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true
typeset -g POWERLEVEL9K_MODE=nerdfont-complete
typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=true
typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(dir vcs prompt_char)
typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status command_execution_time background_jobs time)

# Catppuccin Mocha-ish 256-colour accents
typeset -g POWERLEVEL9K_DIR_FOREGROUND=117
typeset -g POWERLEVEL9K_VCS_CLEAN_FOREGROUND=150
typeset -g POWERLEVEL9K_VCS_MODIFIED_FOREGROUND=223
typeset -g POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND=117
typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_FOREGROUND=150
typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_FOREGROUND=211
typeset -g POWERLEVEL9K_TIME_FOREGROUND=183
typeset -g POWERLEVEL9K_STATUS_OK=false
typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=3
