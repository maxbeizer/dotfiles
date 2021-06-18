#!/bin/bash

exec > >(tee -i $HOME/dotfiles_install.log)
exec 2>&1
set -x

fancy_echo() {
  local fmt="$1"; shift

  # shellcheck disable=SC2059
  printf "\\n$fmt\\n" "$@"
}

get() {
  wget -c $1 -O $2
}

if [ "$CODESPACES" == "true" ]; then
  fancy_echo "In codespaces! Installing dotfiles"

  ln -s $(pwd)/tmux.conf.local $HOME/.tmux.conf.local
  ln -s $(pwd)/vimrc.local $HOME/.vimrc.local
  ln -s $(pwd)/vimrc.bundles.local $HOME/.vimrc.bundles.local
  ln -s $(pwd)/aliases.local $HOME/.aliases.local

  fancy_echo "Getting thoughtbot dotfiles"

  get https://raw.githubusercontent.com/thoughtbot/dotfiles/master/vimrc $HOME/.vimrc
  get https://raw.githubusercontent.com/thoughtbot/dotfiles/master/vimrc.bundles $HOME/.vimrc.bundles
  get https://raw.githubusercontent.com/thoughtbot/dotfiles/master/aliases $HOME/.aliases
  get https://raw.githubusercontent.com/thoughtbot/dotfiles/master/gitconfig $HOME/.gitconfig
  get https://raw.githubusercontent.com/thoughtbot/dotfiles/master/gitmessage $HOME/.gitmessage
  get https://raw.githubusercontent.com/thoughtbot/dotfiles/master/gitignore $HOME/.gitignore

  if [ -e "$HOME"/.vim/autoload/plug.vim ]; then
    vim -E -s +PlugUpgrade +qa
  else
    mkdir "$HOME"/.vim/autoload/
    get https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim "$HOME"/.vim/autoload/plug.vim
  fi
  vim -u "$HOME"/.vimrc.bundles +PlugUpdate +PlugClean! +qa
  reset -Q

  [[ -f ~/.aliases ]] && source ~/.aliases

  export EDITOR=vim

  fancy_echo "All done"
else
  fancy_echo "Not running in a codespace"
fi
