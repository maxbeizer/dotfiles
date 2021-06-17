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
  wget $1 $2
}

if [ "$CODESPACE" == "true" ]
then
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

  vim -Es -u $HOME/.vimrc -c "PlugInstall | qa"

  [[ -f ~/.aliases ]] && source ~/.aliases

  export EDITOR=vim

  fancy_echo "All done"
fi
