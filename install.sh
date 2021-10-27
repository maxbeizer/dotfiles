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
  curl -fLo $1 --create-dirs $2
}

if [ "$CODESPACES" == "true" ]; then
  fancy_echo "In codespaces! Installing dotfiles"
  locals=( "tmux.conf.local" "vimrc.local" "vimrc.bundles.local" "aliases.local" "gitconfig.local" "ripgreprc" )
  for i in "${locals[@]}"
  do
    ln -s $(pwd)/"$i" $HOME/."$i"
  done

  fancy_echo "Installing apt-get packages"
  apt-get install fzf ctags

  fancy_echo "Getting thoughtbot dotfiles"
  get $HOME/.vimrc https://raw.githubusercontent.com/thoughtbot/dotfiles/master/vimrc
  get $HOME/.vimrc.bundles https://raw.githubusercontent.com/thoughtbot/dotfiles/master/vimrc.bundles
  get $HOME/.aliases https://raw.githubusercontent.com/thoughtbot/dotfiles/master/aliases
  get $HOME/.gitconfig https://raw.githubusercontent.com/thoughtbot/dotfiles/master/gitconfig
  get $HOME/.gitmessage https://raw.githubusercontent.com/thoughtbot/dotfiles/master/gitmessage
  get $HOME/.gitignore https://raw.githubusercontent.com/thoughtbot/dotfiles/master/gitignore
  get $HOME/.tmux.conf https://raw.githubusercontent.com/thoughtbot/dotfiles/master/tmux.conf

  fancy_echo "Installing vim plugins"
  if [ -e "$HOME"/.vim/autoload/plug.vim ]; then
    vim -E -s +PlugUpgrade +qa
  else
    curl -fLo "$HOME"/.vim/autoload/plug.vim --create-dirs \
      https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  fi
  vim -u "$HOME"/.vimrc.bundles +PlugUpdate +PlugClean! +qa
  reset -Q

  fancy_echo "Setting up neovim"
  brew install neovim
  mkdir -p "$HOME"/.config/nvim
  echo "set runtimepath^=~/.vim runtimepath+=~/.vim/after" >> "$HOME"/.config/nvim/init.vim
  echo "let &packpath=&runtimepath" >> "$HOME"/.config/nvim/init.vim
  echo "source ~/.vimrc" >> "$HOME"/.config/nvim/init.vim

  fancy_echo "Sourcing aliases"
  [[ -f ~/.aliases ]] && source ~/.aliases
  echo "alias g='git'" >> "$HOME"/.bashrc
  echo "export EDITOR=vim" >> "$HOME"/.bashrc

  fancy_echo "Installing gems"
  sudo gem install ripper-tags
  sudo ripper-tags -R --exclude=vendor

  fancy_echo "Sourcing bashrc"
  source ~/.bashrc

  fancy_echo "All done"
else
  fancy_echo "Not running in a codespace"
fi
