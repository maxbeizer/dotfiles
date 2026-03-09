# Force block cursor in every new prompt line.
# vi-mode (bindkey -v) switches to a beam in insert mode;
# this overrides that so we always get a fat block cursor.
_force_block_cursor() {
  printf '\e[2 q'
}

zle -N zle-line-init _force_block_cursor
