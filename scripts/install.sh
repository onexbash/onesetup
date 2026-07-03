#!/usr/bin/env bash

# exit on error, undefined variables, and failed commands in pipes
set -euo pipefail

# -- TERMINAL COLORS -- #
export C_BLACK='\033[1;30m'
export C_RED='\033[1;31m'
export C_GREEN='\033[1;32m'
export C_YELLOW='\033[1;33m'
export C_BLUE='\033[1;34m'
export C_PURPLE='\033[1;35m'
export C_CYAN='\033[1;36m'
export C_WHITE='\033[1;37m'
export C_GRAY='\033[1;34m'
export C_RESET='\033[0m'

# -- INFO PROMPTS -- #
export I_SKIP="${C_BLACK}[${C_CYAN} SKIPPING ${C_BLACK}] ${C_RESET}"   # skipping
export I_WARN="${C_BLACK}[${C_YELLOW} WARNING ${C_BLACK}] ${C_RESET}"  # warning
export I_OK="${C_BLACK}[${C_GREEN}  OK  ${C_BLACK}] ${C_RESET}"        # ok
export I_INFO="${C_BLACK}[${C_PURPLE} INFO ${C_BLACK}] ${C_RESET}"     # info
export I_ERR="${C_BLACK}[${C_YELLOW} ERROR ${C_BLACK}] ${C_RESET}"     # error
export I_YN="${C_BLACK}[${C_BLUE} y/n ${C_BLACK}] ${C_RESET}"          # ask user for yes/no
export I_ASK="${C_BLACK}[${C_BLUE} ? ${C_BLACK}] ${C_RESET}"           # ask user for anything
export I_LOAD="${C_BLACK}[${C_BLUE} LOADING .. ${C_BLACK}] ${C_RESET}" # ask user for anything

function main() {
  # Environment Variable Defaults (overwritten if set by user)
  if [[ -z "${ONESETUP_DIR:-}" ]]; then
    export ONESETUP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/onesetup"
  fi
  if [[ -z "${ONESETUP_REPO:-}" ]]; then
    export ONESETUP_REPO="onexbash/onesetup"
  fi
  if [[ -z "${ANSIBLE_DEBUG:-}" ]]; then
    export ANSIBLE_DEBUG=0
  fi

  # Variables
  local onesetup_uri_raw="https://raw.githubusercontent.com/${ONESETUP_REPO}/main"
  local onesetup_uri_https="https://github.com/${ONESETUP_REPO}.git"
  local onesetup_uri_ssh="git@github.com:${ONESETUP_REPO}.git"

  # Function Calls
  # { helper && echo -e "${I_OK}Helper Script Loaded!"; } || echo -e "${I_WARN}Failed to load Helper Script from [$onesetup_uri_raw]"
  { prerequisites && echo -e "${I_OK}Prerequesites satisfied!"; } || echo -e "${I_WARN}Failed to ensure that prerequesites are satisfied."
  { install && echo -e "${I_OK}Onesetup Installed"; } || { echo -e "${I_ERR}Failed to install Onesetup." && exit 1; }
}

# Load Helper Script
# function helper() {
#   # Ensure $TMPDIR is set
#   export TMPDIR="${TMPDIR:-/tmp}"
#
#   # Create temp dir
#   local tmp_dir
#   tmp_dir=$(mktemp --directory --tmpdir "onesetup-XXXXXX")
#   echo "tmp_dir: $tmp_dir"
#
#   # Curl helper script from repository & store as tmp file
#   curl -fs "$onesetup_uri_raw/scripts/helper.sh" -o "$tmp_dir/helper.sh"
#
#   # Source helper script
#   { source "$tmp_dir/helper.sh" && echo -e "${I_OK}Helper Script Loaded."; } || { echo -e "${I_ERR}Failed to load Helper Script. Please ensure your installation was correct." && exit 1; }
#   sudo rm -rf "$tmp_dir" || echo -e "${I_WARN}Failed to cleanup temp directory: $tmp_dir"
# }

# Ensure prerequisites are satisfied
function prerequisites() {
  # homebrew
  if [[ "$OS" = "macos" ]]; then
    if ! command -v "brew" &>/dev/null; then
      echo -e "${I_ERR}Homebrew not available. Please install from 'https://brew.sh' & re-run script"
    fi
  fi

  # git
  if ! command -v "git" &>/dev/null; then
    case "$OS" in
    linux) sudo dnf install -y git ;;
    macos) brew install git ;;
    esac
  fi

  # gum
  if ! command -v "gum" &>/dev/null; then
    case "$OS" in
    linux) sudo dnf install -y "gum" && echo -e "${I_OK}gum installed!" || echo -e "${I_ERR}failed to install gum!" ;;
    macos) brew install "gum" && echo -e "${I_OK}gum installed!" || echo -e "${I_ERR}failed to install gum!" ;;
    esac
  fi
}

function install() {
  # Check if installation directory is a git repository
  if [[ -d "$ONESETUP_DIR" ]]; then
    if ! git -C "$ONESETUP_DIR" rev-parse --git-dir >/dev/null 2>&1; then
      sudo rm -rf "$ONESETUP_DIR" && echo -e "${I_INFO}There was a broken installation at $ONESETUP_DIR. Deletion complete."
    fi
  fi

  # Check if installation directory is up-to-date
  if [[ -d "$ONESETUP_DIR" ]]; then
    git -C "$ONESETUP_DIR" fetch
    local behind_count
    local ahead_count
    behind_count=$(git -C "$ONESETUP_DIR" rev-list --count HEAD..@{u})
    ahead_count=$(git -C "$ONESETUP_DIR" rev-list --count @{u}..HEAD)
    if (($behind_count > 0)) || (($ahead_count > 0)); then
      if (($behind_count > 0)) && (($ahead_count > 0)); then
        echo -e "${I_WARN}The installation directory is $behind_count commits behind and $ahead_count commits ahead of the remote (https://github.com/$ONESETUP_REPO)."
        echo -e "${I_ERR}Please Check! Exiting.." && exit 0
      elif (($ahead_count > 0)); then
        echo -e "${I_WARN}The installation directory is $ahead_count commits ahead of the remote (https://github.com/$ONESETUP_REPO)."
        echo -e "${I_ERR}Please Check! Exiting.." && exit 0
      elif (($behind_count > 0)); then
        echo -e "${I_INFO}The installation directory is $behind_count commits behind of the remote (https://github.com/$ONESETUP_REPO)."
        echo -e "${I_INFO}Updating.."
        sudo rm -rf "$ONESETUP_DIR" && sudo git clone "$onesetup_uri_https" "$ONESETUP_DIR"
      fi
    else
      echo -e "${I_WARN}The installation directory is up-to-date with the remote (https://github.com/$ONESETUP_REPO)."
      echo -e "${I_INFO}Skipping installation.."
    fi
  fi

  # Install only if directory is empty.
  if [[ ! -d "$ONESETUP_DIR" ]]; then
    echo -e "${I_INFO}Onesetup is not installed yet. Installing to ${ONESETUP_DIR} .." && sleep 1
    sudo git clone "$onesetup_uri_https" "$ONESETUP_DIR" && echo -e "${I_OK}Installation complete!"
  fi

  # Set permissions
  sudo chmod 774 "$ONESETUP_DIR" && echo -e "${I_OK}Permissions on installation directory set! (744): $ONESETUP_DIR" || echo -e "${I_ERR}Failed to set permissions on installation directory! (744): $ONESETUP_DIR"
  sudo chown -R "$USER:wheel" "$ONESETUP_DIR" && echo -e "${I_OK}Ownership on installation directory set! ($USER:wheel): $ONESETUP_DIR" || echo -e "${I_ERR}Failed to set ownership on installation directory! ($USER:wheel): $ONESETUP_DIR"

  # Ensure bin directory exists
  local bin_dir="/usr/local/bin"
  if [[ -d "$bin_dir" ]]; then
    echo -e "${I_OK}Bin Directory found at: [ ${FG_GREEN}$bin_dir${S_RESET} ]"
  else
    sudo mkdir -p "$bin_dir"
    echo -e "${I_OK}Bin Directory not found and therefore created at: [ ${FG_GREEN}$bin_dir${S_RESET} ]"
  fi

  # Rollout executables to bin_dir
  if [[ -z "${ONESETUP_DIR:-}" ]]; then
    export ONESETUP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/onesetup"
  fi
  for file in "${ONESETUP_DIR}"/bin/*; do
    if [[ -f "$file" ]]; then
      local filename
      filename=$(basename "$file")
      sudo cp -f "$file" "$bin_dir" && echo -e "${I_OK}${FG_GREEN}$filename${S_RESET} copied to ${FG_GREEN}$bin_dir${S_RESET}" || echo -e "${I_ERR}Failed to copy ${FG_RED}$filename${S_RESET} to ${FG_RED}$bin_dir${S_RESET}"
    fi
  done
}

# Call Main Function with args
main "$@"
