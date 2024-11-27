#!/usr/bin/env zsh
function src_zdotdir(){
  source "${ZDOTDIR:-$HOME/.config/zsh}/environment.zsh" # environment variables
}
src_zdotdir

# -- XDG VARIABLES -- #
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"

# -- SHORTEN PATHS -- #
export APPSUP="$HOME/Library/Application Support"
export NVIM="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
export ENV="${XDG_CONFIG_HOME:-$HOME/.config}/scripts/env.zsh"

# -- ONE DIRECTORIES -- #
export ONECLOUD="$HOME/one-cloud" ; export CLOUD="$ONECLOUD"
export ONEDEV="$ONECLOUD/dev" ; export DEV="$ONEDEV"
export ONEVAULT="$ONECLOUD/vault" ; export VAULT="$ONEVAULT"
export ONETMP="$ONECLOUD/storage/tmp" ; export TMP="$ONETMP"

# -- DIRECTORY VARIABLES -- #
# dotnet
export DOTNET_ROOT="/opt/homebrew/opt/dotnet/libexec"
# starship
export STARSHIP_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/starship/starship.toml"
# pnpm
export PNPM_HOME="${XDG_CONFIG_HOME:-$HOME/.config}/pnpm"
# openssl
# export PKG_CONFIG_PATH="$(brew --prefix openssl)/lib/pkgconfig"

# -- SYSTEM VARIABLES -- #
export EDITOR="nvim"
export VISUAL="nvim"
export BROWSER="firefox"
export HOSTNAME="mac-one"
export TMPDIR="$ONETMP"

# -- 3RD PARTY TOOL ENV VARS -- #
export GNUPGHOME="/opt/gnupg" # gnupg home dir
export GPG_TTY=$(tty) # fixes inappropriate ioctl for device error
export BAT_CONFIG_PATH="${XDG_CONFIG_HOME:-$HOME/.config}/bat/bat.conf"
