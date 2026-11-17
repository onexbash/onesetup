#!/usr/bin/env bash

# --                             -- #
# --     INSTALLATION SCRIPT     -- #
# --                             -- #
# Installs the onesetup commands to ONESETUP_BIN_DIR. Run 'onesetup-init' afterwards.
# Optional environment variables: ONESETUP_BIN_DIR, ONESETUP_REPO (GitHub HTTPS URL), ONESETUP_BRANCH
# Options (piped: curl ... | bash -s -- --branch <branch>):
#   --branch <branch>   branch to install the commands from (overrides ONESETUP_BRANCH, default: main)

set -eo pipefail

# -- Main Function -- #
function main() {
  tty_styles
  parse_args "$@"
  rollout_executables
}

# Parse Command Arguments
function parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
    --branch)
      if [[ -z "${2:-}" || "$2" == --* ]]; then
        echo -e "${I_ERR}Option '--branch' requires a value." >&2
        exit 1
      fi
      ONESETUP_BRANCH="$2"
      shift 2
      ;;
    *)
      echo -e "${I_ERR}Unknown option: $1 (usage: install.sh [--branch <branch>])" >&2
      exit 1
      ;;
    esac
  done
}

# Rollout Executables
function rollout_executables() {
  local bin_dir="${ONESETUP_BIN_DIR:-/usr/local/bin}"
  local repo="${ONESETUP_REPO:-https://github.com/onexbash/onesetup.git}"
  local branch="${ONESETUP_BRANCH:-main}"
  local root_user root_group repo_path repo_url tmp_dir check_path file
  local executables=("onesetup" "onesetup-init" "onesetup-util" "onesetup-vault")
  root_user="$(id -nu 0)"
  root_group="$(id -ng 0)"

  # Raw file URL (only GitHub HTTPS URLs are supported by this bootstrap script)
  case "$repo" in
  https://github.com/*) repo_path="${repo#https://github.com/}" ;;
  *)
    echo -e "${I_ERR}Unsupported ONESETUP_REPO: $repo (expected https://github.com/<owner>/<repo>.git)" >&2
    return 1
    ;;
  esac
  repo_url="https://raw.githubusercontent.com/${repo_path%.git}/${branch}"

  # Check if bin dir is protected by MacOS SIP (System Integrity Protection)
  if [[ "$(uname -s)" == "Darwin" ]]; then
    check_path="$bin_dir"
    while [[ ! -e "$check_path" ]]; do check_path="$(dirname "$check_path")"; done
    if /bin/ls -ldO "$check_path" | /usr/bin/grep -q "restricted"; then
      echo -e "${I_ERR}$bin_dir is protected by System Integrity Protection, use e.g. /usr/local/bin" >&2
      return 1
    fi
  fi

  # Ensure bin dir exists with 755 and root_user:root_group
  sudo install -d -m 755 -o "$root_user" -g "$root_group" "$bin_dir" || {
    echo -e "${I_ERR}Failed to prepare $bin_dir" >&2
    return 1
  }

  # Create TMP Directory & Cleanup after
  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' EXIT

  # Download & Install Executables
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
  if [[ "$branch" == "main" ]]; then
    echo -e "${I_INFO}Next step: run 'onesetup-init'"
  else
    echo -e "${I_INFO}Next step: run 'ONESETUP_BRANCH=${branch} onesetup-init' (installs the playbook from the same branch)"
  fi
}

# [UTIL] Terminal Colors & Prompts (copy of onesetup-util, which is not installed yet)
function tty_styles() {
  export C_BLACK='\033[1;30m'
  export C_RED='\033[1;31m'
  export C_GREEN='\033[1;32m'
  export C_PURPLE='\033[1;35m'
  export C_RESET='\033[0m'
  export I_OK="${C_BLACK}[${C_GREEN}  OK  ${C_BLACK}] ${C_RESET}"
  export I_INFO="${C_BLACK}[${C_PURPLE} INFO ${C_BLACK}] ${C_RESET}"
  export I_ERR="${C_BLACK}[${C_RED} ERROR ${C_BLACK}] ${C_RESET}"
}

# Call Main Function with args
main "$@"
