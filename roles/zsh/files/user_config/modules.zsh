#!/usr/bin/env zsh

# -- HOMEBREW -- #
export CFG_BREW="$XDG_CONFIG_HOME/homebrew"
export HOMEBREW_API_AUTO_UPDATE_SECS=86400
export HOMEBREW_NO_AUTOREMOVE= # idk
export HOMEBREW_CLEANUP_MAX_AGE_DAYS=1
export HOMEBREW_CASK_OPTS="--fontdir"
export HOMEBREW_DISPLAY=1
export HOMEBREW_NO_ENV_HINTS=1
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - #

# -- RUST -- #
# set cargo env
export CARGO_HOME="${XDG_CONFIG_HOME}/cargo"
# initialize cargo
source "$CARGO_HOME/env"
# -- SDKMAN --#
# set sdkman env
export SDKMAN_DIR=$(brew --prefix sdkman-cli)/libexec
# initialize sdkman
[[ -s "${SDKMAN_DIR}/bin/sdkman-init.sh" ]] && source "${SDKMAN_DIR}/bin/sdkman-init.sh"

# -- NODE VERSION MANAGER -- #
export NVM_DIR="$HOME/.nvm"
  [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
  [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

# -- NODE & PNPM -- #
export PNPM_HOME="${XDG_CONFIG_HOME:-$HOME/.config}/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# -- NVIM -- #
export NVIM_CONFIG_DIR="${XDG_CONFIG_HOME}/nvim"
export NVIM_STATE_DIR="${XDG_STATE_HOME}/nvim"
export NVIM_DATA_DIR="${XDG_DATA_HOME}/nvim"
export NVIM_CACHE_DIR="${XDG_CACHE_HOME}/nvim"
export NVIM_PLUGINS="${NVIM_CONFIG_DIR}/lua/plugins"
export NVIM_UTILS="${NVIM_CONFIG_DIR}/lua/utils"
export NVIM_CORE="${NVIM_CONFIG_DIR}/lua/core"
export NVIM_DOCS="${NVIM_CONFIG_DIR}/docs"
export NVIM_INIT="${NVIM_CONFIG_DIR}/init.lua"
export NVIM_APPNAME="nvim"

# -- GOLANG -- # 
export GOPATH="${XDG_CONFIG_HOME:-$HOME/.config}/go"

# -- ANTHROPIC -- #
# -- STARSHIP -- # 
eval "$(starship init zsh)"

# -- ATUIN -- #
eval "$(atuin init zsh)"

# -- FNM -- #
eval "$(fnm env --use-on-cd --version-file-strategy=recursive --corepack-enabled --resolve-engines --shell zsh)"

# -- FZF -- # 
source <(fzf --zsh)

# -- ZOXIDE -- #
eval "$(zoxide init --cmd cd --hook pwd zsh)" # load zoxide (better cd)
export _ZO_DATA_DIR="$CLOUD/storage/databases" # location of cd history database
