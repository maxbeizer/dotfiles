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
  locals=( "tmux.conf.local" "vimrc.local" "vimrc.bundles.local" "aliases.local" "gitconfig.local" "ripgreprc" "codespaces.local")
  for i in "${locals[@]}"
  do
    ln -s $(pwd)/"$i" $HOME/."$i"
  done

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

  [ -f /workspaces/github ] && export PATH="/workspaces/github/bin:$PATH"

  fancy_echo "Setting up neovim"
  mkdir -p "$HOME"/.config/nvim
  echo "set runtimepath^=~/.vim runtimepath+=~/.vim/after" >> "$HOME"/.config/nvim/init.vim
  echo "let &packpath=&runtimepath" >> "$HOME"/.config/nvim/init.vim
  echo "source ~/.vimrc" >> "$HOME"/.config/nvim/init.vim

  fancy_echo "Sourcing aliases"
  echo "source "$HOME"/.aliases" >> "$HOME"/.bashrc
  echo "alias g='git'" >> "$HOME"/.bashrc
  echo "export EDITOR=vim" >> "$HOME"/.bashrc
  echo "source "$HOME"/.codespaces.local" >> "$HOME"/.bashrc
  echo "machine goproxy.githubapp.com login nobody password $GITHUB_TOKEN" >> $HOME/.netrc

  if [ -d "/workspaces/github/bin" ]; then
    echo "export PATH="$PATH":/workspaces/github/bin" >> "$HOME"/.bashrc
  fi

  # Update the PS1 only if the gh cli is installed
  if ! command -v gh &> /dev/null
  then
    echo "export CODESPACES_FRIENDLY_NAME='$(gh api /user/codespaces/$CODESPACE_NAME | jq .display_name | tr -d '"')'" >> "$HOME"/.bashrc
    echo "export PS1=[$CODESPACES_FRIENDLY_NAME]:$PS1" >> "$HOME"/.bashrc
  fi

  # Install linux brew
  if ! command -v brew &> /dev/null
  then
    test -d ~/.linuxbrew && eval "$(~/.linuxbrew/bin/brew shellenv)"
    test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    test -r ~/.bash_profile && echo "eval \"\$($(brew --prefix)/bin/brew shellenv)\"" >> ~/.bash_profile
    echo "eval \"\$($(brew --prefix)/bin/brew shellenv)\"" >> ~/.profile
  fi

  fanch_echo "Adding bashrc to .bash_profile"
  echo "source $HOME/.bashrc" >> "$HOME"/.bash_profile

  fancy_echo "All done"
else
  fancy_echo "Not running in a codespace"
fi
