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
    Darwin*) echo "osx" ;;
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
    if [[ "$(detect_os)" == "osx" ]]; then
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

# [UTIL] Initialize Homebrew on macOS if installed but not available (missing PATH)
function init_brew(){
  local os="$(detect_os)"
  if [[ "$os" == "osx" ]]; then
    
    if ! command -v brew >/dev/null 2>&1; then
        if [[ -x "/opt/homebrew/bin/brew" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null)"
        elif [[ -x "/usr/local/bin/brew" ]]; then
            eval "$(/usr/local/bin/brew shellenv 2>/dev/null)"
        fi
    fi

  fi
}

# [UTIL] Read User Config File 'onesetup.yml'
function read_config(){
  local config_file

  # Function to override Default Values set in config.yml
  _apply_override() {
    local -n _target="$1"; local _val
    _val="$(yq "$2" "$config_file" 2>/dev/null)"
    [[ -n "$_val" && "$_val" != "null" ]] && _target="${_val/#\~/$HOME}"
  }

  # -- Default Values -- #
  # [Remote]
  local remote_provider="github"
  local remote_username="onexbash"
  local remote_connection="https"
  local remote_project_repo="onesetup"
  local remote_dotfiles_repo="dotfiles"
  # [System]
  # Operating System (Auto-Detect)
  local system_os; system_os="$(detect_os)"
  # Username & Group of Default User & Admin/Root User (Auto-Detect)
  local system_username system_root_user system_user_group system_admin_group
  case "$system_os" in
    osx|linux)
      system_username="$USER"
      system_root_user="$(id -nu 0)"
      system_user_group="$(id -ng)"
      system_admin_group="$(id -ng 0)"
      ;;
    windows)
    system_username="${USERNAME:-$(whoami | sed 's/.*\\//')}"
    system_root_user="$(powershell.exe -NoProfile -Command '(Get-LocalUser -ErrorAction SilentlyContinue | Where-Object { $_.SID -like "*-500" }).Name' | tr -d '\r')"
    system_user_group="$(powershell.exe -NoProfile -Command '(Get-LocalGroup | Where-Object { $_.SID -like "*-545" }).Name' | tr -d '\r')"
    system_admin_group="$(powershell.exe -NoProfile -Command '(Get-LocalGroup | Where-Object { $_.SID -like "*-544" }).Name' | tr -d '\r')"
    ;;
    *)
      echo -e "${I_ERR}Unsupported Operating System: $system_os"; return 1 ;;
  esac

  # Directory Locations of: Config-Dir, Install-Dir, Storage-Dir, Dotfiles-Dir, Bin-Dir, TMP-Dir
  local system_config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/onesetup"
  local system_install_dir="${XDG_DATA_HOME:-$HOME/.local/share}/onesetup"
  local system_storage_dir="${XDG_STATE_HOME:-$HOME/.local/state}/onesetup"
  local system_dotfiles_dir="${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles"
  local system_bin_dir="/usr/local/bin"
  local system_tmp_dir="/tmp"
  # [Project]
  # Development-Mode to specify whether to run playbook on Install-Dir or the Git Repo (for executing the onesetup executable via ./bin/onesetup instead of the command rolled-out to Bin-Dir)
  local project_development="false"
  # Debug-Level for Scripts & Ansible itself
  local project_debug="0"
  # -- / -- #
  
  # Ensure Config Directory exists with right permissions
  local config_file="${system_config_dir}/config.yml"
  ensure_directory "$system_config_dir" "755" "${system_username}:${system_user_group}"

  # Ensure yq is present to parse config file
  if ! command -v "yq" &>/dev/null; then
    case "$system_os" in
      linux) { sudo dnf install -y "yq" && echo -e "${I_OK}Installation succeeded: yq" ;} || { echo -e "${I_ERR}Installation failed: yq"; return 1; } ;;
      osx) { brew install "yq" && echo -e "${I_OK}Installation succeeded: yq" ;} || { echo -e "${I_ERR}Installation failed: yq"; return 1; } ;;
      windows) echo -e "${I_ERR}Windows not supported yet"; return 1 ;;
      unsupported) echo -e "${I_ERR}Unsuported Operating System: $ONESETUP_SYSTEM_OS"; return 1 ;;
    esac
  fi
 
  # Overwrite Defaults with Config File Values
  if [[ -f "$config_file" ]]; then
    _apply_override remote_provider       '.remote.provider'
    _apply_override remote_username       '.remote.username'
    _apply_override remote_connection     '.remote.connection'
    _apply_override remote_project_repo   '.remote.project_repo'
    _apply_override remote_dotfiles_repo  '.remote.dotfiles_repo'
    _apply_override system_os             '.system.os'
    _apply_override system_username       '.system.username'
    _apply_override system_root_user      '.system.root_user'
    _apply_override system_config_dir     '.system.config_dir'
    _apply_override system_install_dir    '.system.install_dir'
    _apply_override system_storage_dir    '.system.storage_dir'
    _apply_override system_dotfiles_dir   '.system.dotfiles_dir'
    _apply_override system_bin_dir        '.system.bin_dir'
    _apply_override system_tmp_dir        '.system.tmp_dir'
    _apply_override system_user_group     '.system.user_group'
    _apply_override system_admin_group    '.system.admin_group'
    _apply_override project_development   '.project.development'
    _apply_override project_debug         '.project.debug'
  fi
  unset -f _apply_override

  # -- Export Values as Environment Variables consumed by Ansible -- #
  export ONESETUP_REMOTE_PROVIDER="${remote_provider}"
  export ONESETUP_REMOTE_USERNAME="${remote_username}"
  export ONESETUP_REMOTE_CONNECTION="${remote_connection}"
  export ONESETUP_REMOTE_PROJECT_REPO="${remote_project_repo}"
  export ONESETUP_REMOTE_DOTFILES_REPO="${remote_dotfiles_repo}"
  export ONESETUP_SYSTEM_OS="${system_os}"
  export ONESETUP_SYSTEM_USERNAME="${system_username}"
  export ONESETUP_SYSTEM_ROOT_USER="${system_root_user}"
  export ONESETUP_SYSTEM_USER_GROUP="${system_user_group}"
  export ONESETUP_SYSTEM_ADMIN_GROUP="${system_admin_group}"
  export ONESETUP_SYSTEM_CONFIG_DIR="${system_config_dir}"
  export ONESETUP_SYSTEM_INSTALL_DIR="${system_install_dir}"
  export ONESETUP_SYSTEM_STORAGE_DIR="${system_storage_dir}"
  export ONESETUP_SYSTEM_DOTFILES_DIR="${system_dotfiles_dir}"
  export ONESETUP_SYSTEM_BIN_DIR="${system_bin_dir}"
  export ONESETUP_SYSTEM_TMP_DIR="${system_tmp_dir}"
  export ONESETUP_PROJECT_DEVELOPMENT="${project_development}"
  export ONESETUP_PROJECT_DEBUG="${project_debug}"
  
  # Dynamic Environment Variables
  local project_uri dotfiles_uri
  case "${ONESETUP_REMOTE_CONNECTION}" in
    ssh)
      project_uri="git@github.com:${ONESETUP_REMOTE_USERNAME}/${ONESETUP_REMOTE_PROJECT_REPO}.git"
      dotfiles_uri="git@github.com:${ONESETUP_REMOTE_USERNAME}/${ONESETUP_REMOTE_DOTFILES_REPO}.git" ;;
    https|*)
      project_uri="https://github.com/${ONESETUP_REMOTE_USERNAME}/${ONESETUP_REMOTE_PROJECT_REPO}.git"
      dotfiles_uri="https://github.com/${ONESETUP_REMOTE_USERNAME}/${ONESETUP_REMOTE_DOTFILES_REPO}.git" ;;
  esac
  export ONESETUP_PROJECT_REPO_URI="${project_uri}"
  export ONESETUP_DOTFILES_REPO_URI="${dotfiles_uri}"
  export ONESETUP_PROJECT_REPO_RAW="https://raw.githubusercontent.com/${ONESETUP_REMOTE_USERNAME}/${ONESETUP_REMOTE_PROJECT_REPO}/main"
  export ONESETUP_DOTFILES_REPO_RAW="https://raw.githubusercontent.com/${ONESETUP_REMOTE_USERNAME}/${ONESETUP_REMOTE_DOTFILES_REPO}/main"
  export ONESETUP_DIR_DEV="${ONESETUP_DIR_DEV:-$(git rev-parse --show-toplevel 2>/dev/null)}"
}

function export_ansible_vars(){
  export ANSIBLE_COLLECTIONS_PATH="${ONESETUP_SYSTEM_STORAGE_DIR}/collections"
}
