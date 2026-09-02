#!/usr/bin/env bash

# --                        -- #
# --     UTILITY SCRIPT     -- #
# --                        -- #
# Collection of Utility Functions called by other scripts

# [UTIL] Terminal Colors & Prompts
function tty_styles() {
  # Terminal Colors
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
  # Info Prompts
  export I_SKIP="${C_BLACK}[${C_CYAN} SKIPPING ${C_BLACK}] ${C_RESET}"   # skipping
  export I_WARN="${C_BLACK}[${C_YELLOW} WARNING ${C_BLACK}] ${C_RESET}"  # warning
  export I_OK="${C_BLACK}[${C_GREEN}  OK  ${C_BLACK}] ${C_RESET}"        # ok
  export I_INFO="${C_BLACK}[${C_PURPLE} INFO ${C_BLACK}] ${C_RESET}"     # info
  export I_ERR="${C_BLACK}[${C_RED} ERROR ${C_BLACK}] ${C_RESET}"     # error
  export I_YN="${C_BLACK}[${C_BLUE} y/n ${C_BLACK}] ${C_RESET}"          # ask user for yes/no
  export I_ASK="${C_BLACK}[${C_BLUE} ? ${C_BLACK}] ${C_RESET}"           # ask user for anything
  export I_LOAD="${C_BLACK}[${C_BLUE} LOADING .. ${C_BLACK}] ${C_RESET}" # ask user for anything
}

# [UTIL] Set Script Modes TODO: refactor this
function set_modes() {
  set -eo pipefail
  TOGGLE_SCRIPT_DEBUG_MODE="${TOGGLE_SCRIPT_DEBUG_MODE:-0}"
  if [[ "$TOGGLE_SCRIPT_DEBUG_MODE" -eq 1 ]]; then
    set -x
    echo -e "${I_OK}Running Script in Debug Mode"
  fi
}

# [UTIL] Detect Operating System
function detect_os() {
  local platform
  platform=$(uname -s)
  case "$platform" in
    Linux*) echo "linux" ;;
    Darwin*) echo "macos" ;;
    CYGWIN* | MINGW* | MSYS*) echo "windows" ;;
    *) echo "unsupported" ;;
  esac
}

# [UTIL] Linux PKG Installer
function install_linux_pkg() {
  local pkg="$1"
  if command -v apt-get &>/dev/null; then
    sudo apt-get update -qq && sudo apt-get install -y "$pkg"
  elif command -v dnf &>/dev/null; then
    sudo dnf install -y "$pkg"
  elif command -v pacman &>/dev/null; then
    sudo pacman -S --noconfirm "$pkg"
  else
    echo -e "${I_ERR}Unsupported package manager." >&2 && return 1
  fi
}

# [UTIL] Ensure Directory presence with right permissions
function ensure_directory() {
  local target_dir="$1" desired_perms="$2" desired_ownership="$3" recursive="${4:-false}"
  local chown_flag=""
  [[ "$recursive" == "true" ]] && chown_flag="-R"
  # Create Directory & set permissions if not present yet
  if [[ ! -d "$target_dir" ]]; then
    sudo mkdir -p "$target_dir"
    sudo chown $chown_flag "$desired_ownership" "$target_dir"
    sudo chmod "$desired_perms" "$target_dir"
  else
    # Check Permissions on existing Directory
    local current_owner current_perms
    if [[ "$(detect_os)" == "macos" ]]; then
      current_owner=$(stat -f "%Su:%Sg" "$target_dir")
      current_perms=$(stat -f "%Lp" "$target_dir")
    else
      current_owner=$(stat -c "%U:%G" "$target_dir")
      current_perms=$(stat -c "%a" "$target_dir")
    fi
    # Set Permissions on existing Directory
    [[ "$current_owner" != "$desired_ownership" ]] && sudo chown $chown_flag "$desired_ownership" "$target_dir"
    [[ "$current_perms" != "$desired_perms" ]] && sudo chmod "$desired_perms" "$target_dir"
  fi
}


# [UTIL] Copy to clipboard
function copy_to_clipboard() {
  if command -v pbcopy &>/dev/null; then pbcopy
  elif command -v wl-copy &>/dev/null; then wl-copy
  elif command -v xclip &>/dev/null; then xclip -selection clipboard 2>/dev/null
  else
    cat
    echo -e "\n${I_WARN}No clipboard tool found — printed above instead." >&2
  fi
}

# [UTIL] Read User Config File 'onesetup.yml'
function read_config(){
  # Set Default Config Values
  # [Remote]
  local remote_provider="github"
  local remote_username="onexbash"
  local remote_connection="https"
  local remote_project_repo="onesetup"
  local remote_dotfiles_repo="dotfiles"
  # [System]
  local system_os="$(detect_os)"
  local system_username="$USER"
  local system_root_user="root"
  local system_config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/onesetup"
  local system_install_dir="$HOME/.local/share/onesetup"
  local system_dotfiles_dir="$HOME/.local/share/dotfiles"
  local system_bin_dir="/usr/local/bin"
  local system_admin_group system_user_group
  if [[ "$system_os" == "linux" ]]; then
    system_admin_group="wheel"
    system_user_group="$(id -gn "$system_username" 2>/dev/null || echo "$system_username")"
  elif [[ "$system_os" == "macos" ]]; then
    system_admin_group="wheel"
    system_user_group="staff"
  elif [[ "$system_os" == "windows" ]]; then
    system_admin_group="admin"
    system_user_group="staff"
  fi
  # [Project]
  local project_development="false"
  local project_ansible_debug="0"
  local project_script_debug="0"
  
  # Ensure Config Directory exists with right permissions
  local config_file="${system_config_dir}/config.yml"
  ensure_directory "$system_config_dir" "755" "${system_username}:${system_user_group}"

  # Ensure yq is present to parse config file
  if ! command -v "yq" &>/dev/null; then
    case "$system_os" in
      linux) { sudo dnf install -y "yq" && echo -e "${I_OK}Installation succeeded: yq" ;} || { echo -e "${I_ERR}Installation failed: yq"; return 1; } ;;
      macos) { brew install "yq" && echo -e "${I_OK}Installation succeeded: yq" ;} || { echo -e "${I_ERR}Installation failed: yq"; return 1; } ;;
      windows) echo -e "${I_ERR}Windows not supported yet"; return 1 ;;
      unsupported) echo -e "${I_ERR}Unsuported Operating System: $ONESETUP_SYSTEM_OS"; return 1 ;;
    esac
  fi
 
  # Overwrite Defaults with Config File Values
  if [[ -f "$config_file" ]]; then
    local val
    # [Remote]: provider
    val=$(yq '.remote.provider' "$config_file" 2>/dev/null)
    if [[ -n "$val" && "$val" != "null" ]]; then
      remote_provider="$val"
    fi
    # [Remote]: username
    val=$(yq '.remote.username' "$config_file" 2>/dev/null)
    if [[ -n "$val" && "$val" != "null" ]]; then
      remote_username="$val"
    fi
    # [Remote]: connection
    val=$(yq '.remote.connection' "$config_file" 2>/dev/null)
    if [[ -n "$val" && "$val" != "null" ]]; then
      remote_connection="$val"
    fi
    # [Remote]: project_repo
    val=$(yq '.remote.project_repo' "$config_file" 2>/dev/null)
    if [[ -n "$val" && "$val" != "null" ]]; then
      remote_project_repo="$val"
    fi
    # [Remote]: dotfiles_repo
    val=$(yq '.remote.dotfiles_repo' "$config_file" 2>/dev/null)
    if [[ -n "$val" && "$val" != "null" ]]; then
      remote_dotfiles_repo="$val"
    fi
    # [System]: os
    val=$(yq '.system.os' "$config_file" 2>/dev/null)
    if [[ -n "$val" && "$val" != "null" ]]; then
      system_os="$val"
    fi
    # [System]: username
    val=$(yq '.system.username' "$config_file" 2>/dev/null)
    if [[ -n "$val" && "$val" != "null" ]]; then
      system_username="$val"
    fi
    # [System]: root_user
    val=$(yq '.system.root_user' "$config_file" 2>/dev/null)
    if [[ -n "$val" && "$val" != "null" ]]; then
      system_root_user="$val"
    fi
    # [System]: config_dir
    val=$(yq '.system.config_dir' "$config_file" 2>/dev/null)
    if [[ -n "$val" && "$val" != "null" ]]; then
      system_config_dir="${val/#\~/$HOME}"
    fi
    # [System]: install_dir
    val=$(yq '.system.install_dir' "$config_file" 2>/dev/null)
    if [[ -n "$val" && "$val" != "null" ]]; then
      system_install_dir="${val/#\~/$HOME}"
    fi
    # [System]: dotfiles_dir
    val=$(yq '.system.dotfiles_dir' "$config_file" 2>/dev/null)
    if [[ -n "$val" && "$val" != "null" ]]; then
      system_dotfiles_dir="${val/#\~/$HOME}"
    fi
    # [System]: bin_dir
    val=$(yq '.system.bin_dir' "$config_file" 2>/dev/null)
    if [[ -n "$val" && "$val" != "null" ]]; then
      system_bin_dir="${val/#\~/$HOME}"
    fi
    # [System]: user_group
    val=$(yq '.system.user_group' "$config_file" 2>/dev/null)
    if [[ -n "$val" && "$val" != "null" ]]; then
      system_user_group="$val"
    fi
    # [System]: admin_group
    val=$(yq '.system.admin_group' "$config_file" 2>/dev/null)
    if [[ -n "$val" && "$val" != "null" ]]; then
      system_admin_group="$val"
    fi
    # [Project]: development
    val=$(yq '.project.development' "$config_file" 2>/dev/null)
    if [[ -n "$val" && "$val" != "null" ]]; then
      project_development="$val"
    fi
    # [Project]: ansible_debug
    val=$(yq '.project.ansible_debug' "$config_file" 2>/dev/null)
    if [[ -n "$val" && "$val" != "null" ]]; then
      project_ansible_debug="$val"
    fi
    # [Project]: script_debug
    val=$(yq '.project.ansible_debug' "$config_file" 2>/dev/null)
    if [[ -n "$val" && "$val" != "null" ]]; then
      project_script_debug="$val"
    fi
  fi

  # Environment Variables: Config Keys
  # Section 'remote'
  export ONESETUP_REMOTE_PROVIDER="${remote_provider}"
  export ONESETUP_REMOTE_USERNAME="${remote_username}"
  export ONESETUP_REMOTE_CONNECTION="${remote_connection}"
  export ONESETUP_REMOTE_PROJECT_REPO="${remote_project_repo}"
  export ONESETUP_REMOTE_DOTFILES_REPO="${remote_dotfiles_repo}" 
  # Section 'system'
  export ONESETUP_SYSTEM_OS="${system_os}"
  export ONESETUP_SYSTEM_USERNAME="${system_username}"
  export ONESETUP_SYSTEM_ROOT_USER="${system_root_user}"
  export ONESETUP_SYSTEM_CONFIG_DIR="${system_config_dir}"
  export ONESETUP_SYSTEM_INSTALL_DIR="${system_install_dir}"
  export ONESETUP_SYSTEM_DOTFILES_DIR="${system_dotfiles_dir}"
  export ONESETUP_SYSTEM_BIN_DIR="${system_bin_dir}"
  export ONESETUP_SYSTEM_USER_GROUP="${system_user_group}"
  export ONESETUP_SYSTEM_ADMIN_GROUP="${system_admin_group}"
  # Section 'project'
  export ONESETUP_PROJECT_DEVELOPMENT="${project_development}"
  export ONESETUP_PROJECT_ANSIBLE_DEBUG="${project_ansible_debug}"
  export ONESETUP_PROJECT_SCRIPT_DEBUG="${project_script_debug}"

  # Environment Variables: Dynamic
  local project_uri dotfiles_uri
  case "${ONESETUP_REMOTE_CONNECTION}" in
    ssh)
      project_uri="git@github.com:${ONESETUP_REMOTE_USERNAME}/${ONESETUP_REMOTE_PROJECT_REPO}.git"
      dotfiles_uri="git@github.com:${ONESETUP_REMOTE_USERNAME}/${ONESETUP_REMOTE_DOTFILES_REPO}.git"
      ;;
    https|*) # default to HTTPS if connection is not set
      project_uri="https://github.com/${ONESETUP_REMOTE_USERNAME}/${ONESETUP_REMOTE_PROJECT_REPO}.git"
      dotfiles_uri="https://github.com/${ONESETUP_REMOTE_USERNAME}/${ONESETUP_REMOTE_DOTFILES_REPO}.git"
      ;;
  esac
  export ONESETUP_PROJECT_REPO_URI="${project_uri}"
  export ONESETUP_DOTFILES_REPO_URI="${dotfiles_uri}"

  export ONESETUP_PROJECT_REPO_RAW="https://raw.githubusercontent.com/${ONESETUP_REMOTE_USERNAME}/${ONESETUP_REMOTE_PROJECT_REPO}/main"
  export ONESETUP_DOTFILES_REPO_RAW="https://raw.githubusercontent.com/${ONESETUP_REMOTE_USERNAME}/${ONESETUP_REMOTE_DOTFILES_REPO}/main"

  export ONESETUP_DIR_DEV="${ONESETUP_DIR_DEV:-$(git rev-parse --show-toplevel 2>/dev/null)}"
}
