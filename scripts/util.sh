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


# [UTIL] Check if a Directory is sudo-writable or protected with MacOS System Integrity Protection
function is_writable() {
  local dir="$1"
  local test_file

  if [[ ! -d "$dir" ]]; then
    echo -e "${I_ERR}Directory does not exist: $dir"
    return 2
  fi

  test_file="${dir}/.onesetup_write_test_$$"

  if sudo touch "$test_file" &>/dev/null; then
    sudo rm -f "$test_file" &>/dev/null
    return 0   # writable
  else
    return 1   # not writable (SIP, read-only mount, ACL, etc.)
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
      current_owner=$(/usr/bin/stat -f "%Su:%Sg" "$target_dir")
      current_perms=$(/usr/bin/stat -f "%Lp" "$target_dir")
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
  _get_config_value() {
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
  local system_storage_dir="${XDG_STATE_HOME:-$HOME/.local/state}/onesetup"
  local system_dotfiles_dir="${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles"
  local system_bin_dir="/usr/local/bin"
  local system_tmp_dir="/tmp"
  # [Project]
  # Development Directory where the Ansible Playbook is executed (used instead of the installation directory when set)
  local project_debug="0" # Debug-Level for Scripts & Ansible itself
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
    _get_config_value remote_provider           '.remote.provider'
    _get_config_value remote_username           '.remote.username'
    _get_config_value remote_connection         '.remote.connection'
    _get_config_value remote_project_repo       '.remote.project_repo'
    _get_config_value remote_dotfiles_repo      '.remote.dotfiles_repo'
    _get_config_value system_os                 '.system.os'
    _get_config_value system_username           '.system.username'
    _get_config_value system_root_user          '.system.root_user'
    _get_config_value system_config_dir         '.system.config_dir'
    _get_config_value system_storage_dir        '.system.storage_dir'
    _get_config_value system_dotfiles_dir       '.system.dotfiles_dir'
    _get_config_value system_bin_dir            '.system.bin_dir'
    _get_config_value system_tmp_dir            '.system.tmp_dir'
    _get_config_value system_user_group         '.system.user_group'
    _get_config_value system_admin_group        '.system.admin_group'
    _get_config_value project_debug             '.project.debug'
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
  export ONESETUP_SYSTEM_STORAGE_DIR="${system_storage_dir}"
  export ONESETUP_SYSTEM_DOTFILES_DIR="${system_dotfiles_dir}"
  export ONESETUP_SYSTEM_BIN_DIR="${system_bin_dir}"
  export ONESETUP_SYSTEM_TMP_DIR="${system_tmp_dir}"
  export ONESETUP_PROJECT_DEBUG="${project_debug}"
}

# Function to export Dynamic Environment Variables that are constructed based on the Env-Vars in read_config()
function export_dynamic_vars(){

  local project_uri dotfiles_uri
  local git_host="" project_uri_raw="" dotfiles_uri_raw=""

  case "${ONESETUP_REMOTE_PROVIDER}" in
    github)
      git_host="github.com"
      project_uri_raw="https://raw.githubusercontent.com/${ONESETUP_REMOTE_USERNAME}/${ONESETUP_REMOTE_PROJECT_REPO}/main"
      dotfiles_uri_raw="https://raw.githubusercontent.com/${ONESETUP_REMOTE_USERNAME}/${ONESETUP_REMOTE_DOTFILES_REPO}/main"
      ;;
    gitlab)
      git_host="gitlab.com"
      project_uri_raw="https://gitlab.com/${ONESETUP_REMOTE_USERNAME}/${ONESETUP_REMOTE_PROJECT_REPO}/-/raw/main"
      dotfiles_uri_raw="https://gitlab.com/${ONESETUP_REMOTE_USERNAME}/${ONESETUP_REMOTE_DOTFILES_REPO}/-/raw/main"
      ;;
    bitbucket)
      git_host="bitbucket.org"
      project_uri_raw="https://bitbucket.org/${ONESETUP_REMOTE_USERNAME}/${ONESETUP_REMOTE_PROJECT_REPO}/raw/main"
      dotfiles_uri_raw="https://bitbucket.org/${ONESETUP_REMOTE_USERNAME}/${ONESETUP_REMOTE_DOTFILES_REPO}/raw/main"
      ;;
    azure_devops)
      # NOTE: org/project/repo hierarchy — ONESETUP_REMOTE_USERNAME is treated as
      # the ORG, and project is assumed to match the repo name (simple-setup convention).
      # Raw content is a REST call (?path=&api-version=), NOT path-appendable like the
      # other three providers — see caveat above before relying on ONESETUP_*_REPO_RAW here.
      project_uri_raw="https://dev.azure.com/${ONESETUP_REMOTE_USERNAME}/${ONESETUP_REMOTE_PROJECT_REPO}/_apis/git/repositories/${ONESETUP_REMOTE_PROJECT_REPO}/items?api-version=7.0&versionDescriptor.version=main&path="
      dotfiles_uri_raw="https://dev.azure.com/${ONESETUP_REMOTE_USERNAME}/${ONESETUP_REMOTE_DOTFILES_REPO}/_apis/git/repositories/${ONESETUP_REMOTE_DOTFILES_REPO}/items?api-version=7.0&versionDescriptor.version=main&path="
      ;;
    *)
      echo -e "${I_ERR}Unsupported Remote Provider: ${ONESETUP_REMOTE_PROVIDER}"
      return 1
      ;;
  esac

  case "${ONESETUP_REMOTE_CONNECTION}" in
    ssh)
      if [[ "${ONESETUP_REMOTE_PROVIDER}" == "azure_devops" ]]; then
        project_uri="git@ssh.dev.azure.com:v3/${ONESETUP_REMOTE_USERNAME}/${ONESETUP_REMOTE_PROJECT_REPO}/${ONESETUP_REMOTE_PROJECT_REPO}"
        dotfiles_uri="git@ssh.dev.azure.com:v3/${ONESETUP_REMOTE_USERNAME}/${ONESETUP_REMOTE_DOTFILES_REPO}/${ONESETUP_REMOTE_DOTFILES_REPO}"
      else
        project_uri="git@${git_host}:${ONESETUP_REMOTE_USERNAME}/${ONESETUP_REMOTE_PROJECT_REPO}.git"
        dotfiles_uri="git@${git_host}:${ONESETUP_REMOTE_USERNAME}/${ONESETUP_REMOTE_DOTFILES_REPO}.git"
      fi
      ;;
    https|*)
      if [[ "${ONESETUP_REMOTE_PROVIDER}" == "azure_devops" ]]; then
        project_uri="https://dev.azure.com/${ONESETUP_REMOTE_USERNAME}/${ONESETUP_REMOTE_PROJECT_REPO}/_git/${ONESETUP_REMOTE_PROJECT_REPO}"
        dotfiles_uri="https://dev.azure.com/${ONESETUP_REMOTE_USERNAME}/${ONESETUP_REMOTE_DOTFILES_REPO}/_git/${ONESETUP_REMOTE_DOTFILES_REPO}"
      else
        project_uri="https://${git_host}/${ONESETUP_REMOTE_USERNAME}/${ONESETUP_REMOTE_PROJECT_REPO}.git"
        dotfiles_uri="https://${git_host}/${ONESETUP_REMOTE_USERNAME}/${ONESETUP_REMOTE_DOTFILES_REPO}.git"
      fi
      ;;
  esac
  

  export ONESETUP_PROJECT_REPO_URI="${project_uri}"
  export ONESETUP_DOTFILES_REPO_URI="${dotfiles_uri}"
  export ONESETUP_PROJECT_REPO_RAW="${project_uri_raw}"
  export ONESETUP_DOTFILES_REPO_RAW="${dotfiles_uri_raw}"

  export ANSIBLE_COLLECTIONS_PATH="${ONESETUP_SYSTEM_STORAGE_DIR}/collections"
}
