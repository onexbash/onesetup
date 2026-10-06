#!/usr/bin/env bash

# --                             -- #
# --     INSTALLATION SCRIPT     -- #
# --                             -- #

# -- Main Function -- #
function main() {
  tty_styles
  read_config
  rollout_executables
}

# Terminal Colors & Prompts
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
  export I_ERR="${C_BLACK}[${C_RED} ERROR ${C_BLACK}] ${C_RESET}"        # error
  export I_YN="${C_BLACK}[${C_BLUE} y/n ${C_BLACK}] ${C_RESET}"          # ask user for yes/no
  export I_ASK="${C_BLACK}[${C_BLUE} ? ${C_BLACK}] ${C_RESET}"           # ask user for anything
  export I_LOAD="${C_BLACK}[${C_BLUE} LOADING .. ${C_BLACK}] ${C_RESET}" # ask user for anything
}

# Rollout Executables
function rollout_executables() {
  local bin_dir="$ONESETUP_SYSTEM_BIN_DIR"

  local repo_username="$ONESETUP_REMOTE_USERNAME"
  local repo_name="$ONESETUP_REMOTE_PROJECT_REPO"
  local repo_provider="$ONESETUP_REMOTE_PROVIDER"
  local repo_branch="dev"
  # local repo_branch="${ONESETUP_REMOTE_BRANCH:-main}"
  local root_user="${ONESETUP_SYSTEM_ROOT_USER}"
  local root_group="${ONESETUP_SYSTEM_ROOT_GROUP}"
  local os="${ONESETUP_SYSTEM_OS}"

  local tmp_dir
  local repo_url
  local check_path
  local executables=("onesetup" "onesetup-init" "onesetup-util" "onesetup-vault")

  # Check if bin dir is protected by MacOS SIP (System Integrity Protection)
  if [[ "$(detect_os)" == "osx" ]]; then
    check_path="$bin_dir"
    while [[ ! -e "$check_path" ]]; do check_path="$(dirname "$check_path")"; done
    if /bin/ls -ldO "$check_path" | /usr/bin/grep -q "restricted"; then
      echo -e "${I_ERR}$bin_dir is protected by System Integrity Protection, use e.g. /usr/local/bin" >&2
      return 1
    fi
  fi

  # Ensure bin dir exists with 755 and root_user:root_group
  install -d -m 755 -o "$root_user" -g "$root_group" "$bin_dir" || {
    echo -e "${I_ERR}Failed to prepare $bin_dir" >&2
    return 1
  }

  # Ensure bin dir is writable with sudo
  sudo test -w "$bin_dir" || {
    echo -e "${I_ERR}$bin_dir is not writable with sudo" >&2
    return 1
  }

  # Resolve raw file URL per provider
  case "$repo_provider" in
  github) repo_url="https://raw.githubusercontent.com/$repo_username/$repo_name/$repo_branch" ;;
  gitlab) repo_url="https://gitlab.com/$repo_username/$repo_name/-/raw/$repo_branch" ;;
  *)
    echo -e "${I_ERR}Unsupported provider: $repo_provider" >&2
    return 1
    ;;
  esac

  # Create TMP Directory & Cleanup after
  tmp_dir="$(mktemp -d)"
  trap "rm -rf '$tmp_dir'" EXIT

  # Download Install Executables
  for file in "${executables[@]}"; do
    curl -fsSL "$repo_url/bin/$file" -o "$tmp_dir/$file" || {
      echo -e "${I_ERR}Failed to download $file" >&2
      return 1
    }
    sudo install -m 755 -o "$root_user" -g "$root_group" "$tmp_dir/$file" "$bin_dir/$file" || {
      echo -e "${I_ERR}Failed to install $file to $bin_dir" >&2
      return 1
    }
    echo -e "${I_OK}Installed: $bin_dir/$file"
  done
}

# --                     -- #
# --      UTILITIES      -- #
# --                     -- #

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

# [UTIL] Read User Config File 'onesetup.yml'
function read_config() {
  local config_file

  # Function to override Default Values set in config.yml
  _get_config_value() {
    local -n _target="$1"
    local _val
    _val="$(yq "$2" "$config_file" 2>/dev/null)"
    [[ -n "$_val" && "$_val" != "null" ]] && _target="${_val/#\~/$HOME}"
  }

  # -- Default Values -- #
  # [Remote]
  local remote_provider="github"
  local remote_username="onexbash"
  local remote_branch="main"
  local remote_connection="https"
  local remote_project_repo="onesetup"
  local remote_dotfiles_repo="dotfiles"
  # [System]
  # Operating System
  local system_os
  system_os="$(detect_os)"
  # CPU Architecture
  local system_arch
  [[ "$(sysctl -n hw.optional.arm64 2>/dev/null)" == "1" ]] && system_arch="arm64" || system_arch="x86"

  # Hostname, Username & Group of Default User & Admin/Root User (Auto-Detect)
  local system_hostname system_username system_root_user system_user_group system_root_group
  case "$system_os" in
  osx | linux)
    system_hostname="$(scutil --get HostName 2>/dev/null || scutil --get LocalHostName 2>/dev/null || hostname -s)"
    system_username="$USER"
    system_root_user="$(id -nu 0)"
    system_user_group="$(id -ng)"
    system_root_group="$(id -ng 0)"
    ;;
  windows)
    system_hostname="${COMPUTERNAME:-$(hostname 2>/dev/null | tr -d '\r')}"
    system_username="${USERNAME:-$(whoami | sed 's/.*\\//')}"
    system_root_user="$(powershell.exe -NoProfile -Command '(Get-LocalUser -ErrorAction SilentlyContinue | Where-Object { $_.SID -like "*-500" }).Name' | tr -d '\r')"
    system_user_group="$(powershell.exe -NoProfile -Command '(Get-LocalGroup | Where-Object { $_.SID -like "*-545" }).Name' | tr -d '\r')"
    system_root_group="$(powershell.exe -NoProfile -Command '(Get-LocalGroup | Where-Object { $_.SID -like "*-544" }).Name' | tr -d '\r')"
    ;;
  *)
    echo -e "${I_ERR}Unsupported Operating System: $system_os"
    return 1
    ;;
  esac

  # Directory Locations of: Config-Dir, Install-Dir, Storage-Dir, Dotfiles-Dir, Bin-Dir, TMP-Dir
  local system_config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/onesetup"
  local system_storage_dir="${XDG_STATE_HOME:-$HOME/.local/state}/onesetup"
  local system_dotfiles_dir="${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles"
  local system_bin_dir="/usr/local/bin"
  local system_tmp_dir="/tmp"
  # [Project]
  # Development Directory where the Ansible Playbook is executed (used instead of the installation directory when set)
  local project_dev_dir="${ONESETUP_PROJECT_DEV_DIR:-}"
  local project_debug="0" # Debug-Level for Scripts & Ansible itself
  # -- / -- #

  # Ensure Config Directory exists with right permissions
  local config_file="${system_config_dir}/config.yml"
  ensure_directory "$system_config_dir" "755" "${system_username}:${system_user_group}"

  # Ensure yq is present to parse config file
  if ! command -v "yq" &>/dev/null; then
    case "$system_os" in
    linux) { sudo dnf install -y "yq" && echo -e "${I_OK}Installation succeeded: yq"; } || {
      echo -e "${I_ERR}Installation failed: yq"
      return 1
    } ;;
    osx) { brew install "yq" && echo -e "${I_OK}Installation succeeded: yq"; } || {
      echo -e "${I_ERR}Installation failed: yq"
      return 1
    } ;;
    windows)
      echo -e "${I_ERR}Windows not supported yet"
      return 1
      ;;
    unsupported)
      echo -e "${I_ERR}Unsupported Operating System: $ONESETUP_SYSTEM_OS"
      return 1
      ;;
    esac
  fi

  # Overwrite Defaults with Config File Values
  if [[ -f "$config_file" ]]; then
    _get_config_value remote_provider '.remote.provider'
    _get_config_value remote_branch '.remote.branch'
    _get_config_value remote_username '.remote.username'
    _get_config_value remote_connection '.remote.connection'
    _get_config_value remote_project_repo '.remote.project_repo'
    _get_config_value remote_dotfiles_repo '.remote.dotfiles_repo'
    _get_config_value system_os '.system.os'
    _get_config_value system_arch '.system.arch'
    _get_config_value system_hostname '.system.hostname'
    _get_config_value system_username '.system.username'
    _get_config_value system_root_user '.system.root_user'
    _get_config_value system_config_dir '.system.config_dir'
    _get_config_value system_storage_dir '.system.storage_dir'
    _get_config_value system_dotfiles_dir '.system.dotfiles_dir'
    _get_config_value system_bin_dir '.system.bin_dir'
    _get_config_value system_tmp_dir '.system.tmp_dir'
    _get_config_value system_user_group '.system.user_group'
    _get_config_value system_root_group '.system.root_group'
    _get_config_value project_debug '.project.debug'
  fi
  unset -f _apply_override

  # -- Export Values as Environment Variables consumed by Ansible -- #
  export ONESETUP_REMOTE_PROVIDER="${remote_provider}"
  export ONESETUP_REMOTE_USERNAME="${remote_username}"
  export ONESETUP_REMOTE_BRANCH="${remote_branch}"
  export ONESETUP_REMOTE_CONNECTION="${remote_connection}"
  export ONESETUP_REMOTE_PROJECT_REPO="${remote_project_repo}"
  export ONESETUP_REMOTE_DOTFILES_REPO="${remote_dotfiles_repo}"
  export ONESETUP_SYSTEM_OS="${system_os}"
  export ONESETUP_SYSTEM_ARCH="${system_arch}"
  export ONESETUP_SYSTEM_HOSTNAME="${system_hostname}"
  export ONESETUP_SYSTEM_USERNAME="${system_username}"
  export ONESETUP_SYSTEM_USER_GROUP="${system_user_group}"
  export ONESETUP_SYSTEM_ROOT_USER="${system_root_user}"
  export ONESETUP_SYSTEM_ROOT_GROUP="${system_root_group}"
  export ONESETUP_SYSTEM_CONFIG_DIR="${system_config_dir}"
  export ONESETUP_SYSTEM_STORAGE_DIR="${system_storage_dir}"
  export ONESETUP_SYSTEM_DOTFILES_DIR="${system_dotfiles_dir}"
  export ONESETUP_SYSTEM_BIN_DIR="${system_bin_dir}"
  export ONESETUP_SYSTEM_TMP_DIR="${system_tmp_dir}"
  export ONESETUP_PROJECT_DEBUG="${project_debug}"
  export ONESETUP_PROJECT_DEV_DIR="${project_dev_dir}"
}

# Call Main Function with args
main "$@"
