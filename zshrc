# load custom executable functions
for function in ~/.zsh/functions/*; do
  source $function
done

# extra files in ~/.zsh/configs/pre, ~/.zsh/configs, and ~/.zsh/configs/post
_load_settings() {
  _dir="$1"
  if [ -d "$_dir" ]; then
    if [ -d "$_dir/pre" ]; then
      for config in "$_dir"/pre/**/*~*.zwc(N-.); do
        . $config
      done
    fi

    for config in "$_dir"/**/*(N-.); do
      case "$config" in
        "$_dir"/(pre|post)/*|*.zwc)
          :
          ;;
        *)
          . $config
          ;;
      esac
    done

    if [ -d "$_dir/post" ]; then
      for config in "$_dir"/post/**/*~*.zwc(N-.); do
        . $config
      done
    fi
  fi
}
_load_settings "$HOME/.zsh/configs"

# homebrew
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# --- local config (formerly zshrc.local) ---

autoload colors; colors;
export LSCOLORS="Gxfxcxdxbxegedabagacad"
setopt prompt_subst
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
setopt NO_BEEP
setopt HIST_IGNORE_SPACE

# prompt — use Starship if available, fall back to hand-rolled
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
else
  # fallback prompt
  ZSH_THEME_GIT_PROMPT_PREFIX="%{$reset_color%}%{$fg[green]%}["
  ZSH_THEME_GIT_PROMPT_SUFFIX="]%{$reset_color%}"
  ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[red]%}*%{$reset_color%}"
  ZSH_THEME_GIT_PROMPT_CLEAN=""

  parse_git_branch() {
    (command git symbolic-ref -q HEAD || command git name-rev --name-only --no-undefined --always HEAD) 2>/dev/null
  }

  parse_git_dirty() {
    if command git diff-index --quiet HEAD 2> /dev/null; then
      echo "$ZSH_THEME_GIT_PROMPT_CLEAN"
    else
      echo "$ZSH_THEME_GIT_PROMPT_DIRTY"
    fi
  }

  git_custom_status() {
    local git_where="$(parse_git_branch)"
    [ -n "$git_where" ] && echo "$ZSH_THEME_GIT_PROMPT_PREFIX${git_where#(refs/heads/|tags/)}$ZSH_THEME_GIT_PROMPT_SUFFIX$(parse_git_dirty)"
  }

  PROMPT='
%{$fg[yellow]%}[%*]%{$reset_color%} %{$fg[cyan]%}%~% 
$(git_custom_status) %(?.%{$fg[green]%}.%{$fg[red]%})%B$%b'
fi

HISTFILE=~/.histfile
HISTSIZE=100000
SAVEHIST=100000

bindkey "^[[A" history-search-backward
bindkey "^[[B" history-search-forward

# environment
export GOPATH=$HOME/code/go
export RIPGREP_CONFIG_PATH=$HOME/.ripgreprc
export PATH="$HOME/.bin:$HOME/.local/bin:$PATH"
export PATH="$PATH:$GOPATH/bin"
export PATH="$PATH:/usr/bin:/usr/local/bin"

# asdf version manager
export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"

# fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# fzf-tab (if installed)
[ -f ~/code/fzf-tab/fzf-tab.plugin.zsh ] && source ~/code/fzf-tab/fzf-tab.plugin.zsh

# zoxide (if installed — replaces z.sh)
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"

# aliases
[[ -f ~/.aliases ]] && source ~/.aliases

# Pull latest dotfiles, re-run install, reload shell
dotup() {
  local dotdir="${DOTFILES_DIR:-$HOME/dotfiles-local}"
  echo "Updating dotfiles from $dotdir..."
  (cd "$dotdir" && git pull --quiet) &&
  bash "$dotdir/install.sh" &&
  exec zsh -l
}
