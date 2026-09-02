#!/usr/bin/env bash

# Read User Config File 'onesetup.yml'
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
      linux) sudo dnf install -y "yq" ;;
      macos) brew install "yq" ;;
      *) echo -e "${I_ERR}Unsupported OS ($system_os) — cannot install yq automatically."; return 1 ;;
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
