#!/usr/bin/env zsh

# -- SOURCE SHELL CONFIG FILES -- #
function src_zdotdir(){
  source "${ZDOTDIR:-$HOME/.config/zsh}/variables.zsh" # variables
  source "${ZDOTDIR:-$HOME/.config/zsh}/secrets.zsh" # secrets
  source "${ZDOTDIR:-$HOME/.config/zsh}/functions.zsh" # functions
  source "${ZDOTDIR:-$HOME/.config/zsh}/aliases.zsh" # aliases
  source "${ZDOTDIR:-$HOME/.config/zsh}/options.zsh" # options
  source "${ZDOTDIR:-$HOME/.config/zsh}/modules.zsh" # modules
  source "${ZDOTDIR:-$HOME/.config/zsh}/commands.zsh" # commands
  source "${ZDOTDIR:-$HOME/.config/zsh}/path.zsh" # path
}
# -- BEFORE -- #
function execute_before() {

  # brew zsh completions
  if type brew &>/dev/null
  then
    FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
  
    autoload -Uz compinit
    compinit
  fi
  # zsh-syntax-highlighting
  source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
}

# -- AFTER -- #
function execute_after() {
  export PYENV_ROOT="$HOME/.pyenv"
  [[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init -)"
  eval "$(pyenv virtualenv-init -)"
}

execute_before && src_zdotdir && execute_after
