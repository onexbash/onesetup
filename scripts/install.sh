#!/usr/bin/env bash

# --                             -- #
# --     INSTALLATION SCRIPT     -- #
# --                             -- #

# -- Main Function -- #
function main() {
  tty_styles
  apply_config
  rollout_executables
}

# Rollout Executables
function rollout_executables() {
  local bin_dir="$ONESETUP_SYSTEM_BIN_DIR"

  local repo_username="$ONESETUP_REMOTE_USERNAME"
  local repo_name="$ONESETUP_REMOTE_PROJECT_REPO"
  local repo_provider="$ONESETUP_REMOTE_PROVIDER"
  local repo_branch="${ONESETUP_REMOTE_BRANCH:-main}"
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
# NOTE: can not use onesetup-util because that would be a chicken-egg-problem.
# NOTE: the functions below are copied from there tho.

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
  export I_ERR="${C_BLACK}[${C_RED} ERROR ${C_BLACK}] ${C_RESET}"        # error
  export I_YN="${C_BLACK}[${C_BLUE} y/n ${C_BLACK}] ${C_RESET}"          # ask user for yes/no
  export I_ASK="${C_BLACK}[${C_BLUE} ? ${C_BLACK}] ${C_RESET}"           # ask user for anything
  export I_LOAD="${C_BLACK}[${C_BLUE} LOADING .. ${C_BLACK}] ${C_RESET}" # ask user for anything
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

# [UTIL] Apply the user configuration by reading the values from config.yml & environment variables
# NOTE: env-var > config-key > default
function apply_config() {
  local config_file detected_os remote_host remote_base
  detected_os="$(detect_os)"

  # Resolve & export a value from Env-Var or Config-Key
  # Returns 1 if neither provided a value, so the caller can export the default lazily
  _resolve_value() {
    local _name="$1" _key="$2" _val
    # 1. Environment variable already set (non-empty): keep & export it
    if [[ -n "${!_name:-}" ]]; then
      export "$_name"
      return 0
    fi
    # 2. Config key
    if [[ -n "$_key" && -f "$config_file" ]]; then
      _val="$(yq "$_key" "$config_file" 2>/dev/null)"
      if [[ -n "$_val" && "$_val" != "null" ]]; then
        printf -v "$_name" '%s' "${_val/#\~/$HOME}"
        export "$_name"
        return 0
      fi
    fi
    return 1
  }

  # config-dir must be known before the config file can be read (Env-Var > Default)
  export ONESETUP_SYSTEM_CONFIG_DIR="${ONESETUP_SYSTEM_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/onesetup}"
  config_file="${ONESETUP_SYSTEM_CONFIG_DIR}/config.yml"

  # Ensure yq is present to parse config file (based on the real host OS)
  if ! command -v "yq" &>/dev/null; then
    case "$detected_os" in
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
    *)
      echo -e "${I_ERR}Unsupported Operating System: $detected_os"
      return 1
      ;;
    esac
  fi

  # -- [Remote] -- #
  _resolve_value ONESETUP_REMOTE_PROVIDER '.remote.provider' || export ONESETUP_REMOTE_PROVIDER="github"
  _resolve_value ONESETUP_REMOTE_USERNAME '.remote.username' || export ONESETUP_REMOTE_USERNAME="onexbash"
  _resolve_value ONESETUP_REMOTE_CONNECTION '.remote.connection' || export ONESETUP_REMOTE_CONNECTION="https"
  _resolve_value ONESETUP_REMOTE_PROJECT_REPO '.remote.project_repo' || export ONESETUP_REMOTE_PROJECT_REPO="onesetup"
  _resolve_value ONESETUP_REMOTE_DOTFILES_REPO '.remote.dotfiles_repo' || export ONESETUP_REMOTE_DOTFILES_REPO="dotfiles"

  # -- [System] OS & CPU Architecture -- #
  _resolve_value ONESETUP_SYSTEM_OS '.system.os' || export ONESETUP_SYSTEM_OS="$detected_os"
  if ! _resolve_value ONESETUP_SYSTEM_ARCH '.system.arch'; then
    if [[ "$(sysctl -n hw.optional.arm64 2>/dev/null)" == "1" || "$(uname -m)" == "aarch64" ]]; then
      export ONESETUP_SYSTEM_ARCH="arm64"
    else
      export ONESETUP_SYSTEM_ARCH="x86"
    fi
  fi

  # -- [System] Hostname, Username & Group of Default User & Admin/Root User -- #
  case "$ONESETUP_SYSTEM_OS" in
  osx | linux)
    _resolve_value ONESETUP_SYSTEM_HOSTNAME '.system.hostname' ||
      export ONESETUP_SYSTEM_HOSTNAME="$(scutil --get HostName 2>/dev/null || scutil --get LocalHostName 2>/dev/null || hostname -s)"
    _resolve_value ONESETUP_SYSTEM_USERNAME '.system.username' || export ONESETUP_SYSTEM_USERNAME="$USER"
    _resolve_value ONESETUP_SYSTEM_ROOT_USER '.system.root_user' || export ONESETUP_SYSTEM_ROOT_USER="$(id -nu 0)"
    _resolve_value ONESETUP_SYSTEM_USER_GROUP '.system.user_group' || export ONESETUP_SYSTEM_USER_GROUP="$(id -ng)"
    _resolve_value ONESETUP_SYSTEM_ROOT_GROUP '.system.root_group' || export ONESETUP_SYSTEM_ROOT_GROUP="$(id -ng 0)"
    ;;
  windows)
    _resolve_value ONESETUP_SYSTEM_HOSTNAME '.system.hostname' ||
      export ONESETUP_SYSTEM_HOSTNAME="${COMPUTERNAME:-$(hostname 2>/dev/null | tr -d '\r')}"
    _resolve_value ONESETUP_SYSTEM_USERNAME '.system.username' ||
      export ONESETUP_SYSTEM_USERNAME="${USERNAME:-$(whoami | sed 's/.*\\//')}"
    _resolve_value ONESETUP_SYSTEM_ROOT_USER '.system.root_user' ||
      export ONESETUP_SYSTEM_ROOT_USER="$(powershell.exe -NoProfile -Command '(Get-LocalUser -ErrorAction SilentlyContinue | Where-Object { $_.SID -like "*-500" }).Name' | tr -d '\r')"
    _resolve_value ONESETUP_SYSTEM_USER_GROUP '.system.user_group' ||
      export ONESETUP_SYSTEM_USER_GROUP="$(powershell.exe -NoProfile -Command '(Get-LocalGroup | Where-Object { $_.SID -like "*-545" }).Name' | tr -d '\r')"
    _resolve_value ONESETUP_SYSTEM_ROOT_GROUP '.system.root_group' ||
      export ONESETUP_SYSTEM_ROOT_GROUP="$(powershell.exe -NoProfile -Command '(Get-LocalGroup | Where-Object { $_.SID -like "*-544" }).Name' | tr -d '\r')"
    ;;
  *)
    echo -e "${I_ERR}Unsupported Operating System: $ONESETUP_SYSTEM_OS"
    return 1
    ;;
  esac

  # -- [System] Directory Locations -- #
  _resolve_value ONESETUP_SYSTEM_INSTALL_DIR '.system.install_dir' || export ONESETUP_SYSTEM_INSTALL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/onesetup"
  _resolve_value ONESETUP_SYSTEM_STORAGE_DIR '.system.storage_dir' || export ONESETUP_SYSTEM_STORAGE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/onesetup"
  _resolve_value ONESETUP_SYSTEM_DOTFILES_DIR '.system.dotfiles_dir' || export ONESETUP_SYSTEM_DOTFILES_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles"
  _resolve_value ONESETUP_SYSTEM_BIN_DIR '.system.bin_dir' || export ONESETUP_SYSTEM_BIN_DIR="/usr/local/bin"
  _resolve_value ONESETUP_SYSTEM_TMP_DIR '.system.tmp_dir' || export ONESETUP_SYSTEM_TMP_DIR="/tmp"

  # -- [Project] -- #
  # Development Directory where the Ansible Playbook is executed (used instead of the installation directory when set)
  _resolve_value ONESETUP_PROJECT_DEV_DIR '.project.dev_dir' || export ONESETUP_PROJECT_DEV_DIR=""
  _resolve_value ONESETUP_PROJECT_DEBUG '.project.debug' || export ONESETUP_PROJECT_DEBUG="0"

  unset -f _resolve_value

  # Ensure Config Directory exists with right permissions
  ensure_directory "$ONESETUP_SYSTEM_CONFIG_DIR" "755" "${ONESETUP_SYSTEM_USERNAME}:${ONESETUP_SYSTEM_USER_GROUP}"

  # -- Dynamic Environment Variables (constructed from the values above) -- #
  export X_TARGET_DIR="${ONESETUP_PROJECT_DEV_DIR:-$ONESETUP_SYSTEM_INSTALL_DIR}"
  export X_ONESETUP_URI="$(_build_remote_uri "$ONESETUP_REMOTE_PROJECT_REPO")" || return 1
  export X_DOTFILES_URI="$(_build_remote_uri "$ONESETUP_REMOTE_DOTFILES_REPO")" || return 1

  # -- Ansible Variables -- #
  export ANSIBLE_CONFIG="$X_TARGET_DIR/ansible.cfg"
  export ANSIBLE_INVENTORY="$X_TARGET_DIR/inventory.ini"
  # export ANSIBLE_COLLECTIONS_PATH="${ONESETUP_SYSTEM_STORAGE_DIR}/collections"
}

# [UTIL] Build a Git Remote URI from Provider, Connection & Username: _build_remote_uri <repo>
function _build_remote_uri() {
  local repo="$1" host
  case "$ONESETUP_REMOTE_PROVIDER" in
  github) host="github.com" ;;
  gitlab) host="gitlab.com" ;;
  bitbucket) host="bitbucket.org" ;;
  codeberg) host="codeberg.org" ;;
  *.*) host="$ONESETUP_REMOTE_PROVIDER" ;; # Custom host, e.g. git.example.com
  *)
    echo -e "${I_ERR}Unsupported remote provider: $ONESETUP_REMOTE_PROVIDER" >&2
    return 1
    ;;
  esac
  case "$ONESETUP_REMOTE_CONNECTION" in
  https) echo "https://${host}/${ONESETUP_REMOTE_USERNAME}/${repo}.git" ;;
  ssh) echo "git@${host}:${ONESETUP_REMOTE_USERNAME}/${repo}.git" ;;
  *)
    echo -e "${I_ERR}Unsupported remote connection: $ONESETUP_REMOTE_CONNECTION" >&2
    return 1
    ;;
  esac
}

# Call Main Function with args
main "$@"
