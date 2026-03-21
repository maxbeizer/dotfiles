# vi mode
bindkey -v
bindkey "^F" vi-cmd-mode

# handy keybindings
bindkey "^A" beginning-of-line
bindkey "^E" end-of-line
bindkey "^K" kill-line
bindkey "^P" history-search-backward
bindkey "^Y" accept-and-hold
bindkey "^N" insert-last-word
bindkey "^Q" push-line-or-edit

# edit current command in $EDITOR (ctrl-x ctrl-e)
autoload -U edit-command-line
zle -N edit-command-line
bindkey "^X^E" edit-command-line
bindkey -M vicmd v edit-command-line
