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
        log_err "Option '--branch' requires a value."
        exit 1
      fi
      ONESETUP_BRANCH="$2"
      shift 2
      ;;
    *)
      log_err "Unknown option: $1 (usage: install.sh [--branch <branch>])"
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
    log_err "Unsupported ONESETUP_REPO: $repo (expected https://github.com/<owner>/<repo>.git)"
    return 1
    ;;
  esac
  repo_url="https://raw.githubusercontent.com/${repo_path%.git}/${branch}"

  # Check if bin dir is protected by MacOS SIP (System Integrity Protection)
  if [[ "$(uname -s)" == "Darwin" ]]; then
    check_path="$bin_dir"
    while [[ ! -e "$check_path" ]]; do check_path="$(dirname "$check_path")"; done
    if /bin/ls -ldO "$check_path" | /usr/bin/grep -q "restricted"; then
      log_err "$bin_dir is protected by System Integrity Protection, use e.g. /usr/local/bin"
      return 1
    fi
  fi

  # Ensure bin dir exists with 755 and root_user:root_group
  sudo install -d -m 755 -o "$root_user" -g "$root_group" "$bin_dir" || {
    log_err "Failed to prepare $bin_dir"
    return 1
  }

  # Create TMP Directory & Cleanup after
  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' EXIT

  # Download & Install Executables
  for file in "${executables[@]}"; do
    curl -fsSL "$repo_url/bin/$file" -o "$tmp_dir/$file" || {
      log_err "Failed to download $file"
      return 1
    }
    sudo install -m 755 -o "$root_user" -g "$root_group" "$tmp_dir/$file" "$bin_dir/$file" || {
      log_err "Failed to install $file to $bin_dir"
      return 1
    }
    log_ok "Installed: $bin_dir/$file"
  done
  if [[ "$branch" == "main" ]]; then
    log_info "Next step: run 'onesetup-init'"
  else
    log_info "Next step: run 'ONESETUP_BRANCH=${branch} onesetup-init' (installs the playbook from the same branch)"
  fi
}

# [UTIL] Terminal Colors & Log Functions (reduced copy of onesetup-util, which is not installed yet)
function tty_styles() {
  # Colors only when stdout and stderr are terminals and NO_COLOR is not set
  if [[ -t 1 && -t 2 && -z ${NO_COLOR-} ]]; then
    C_RED=$'\033[1;31m' C_GREEN=$'\033[1;32m' C_PURPLE=$'\033[1;35m'
    C_GRAY=$'\033[0;90m' C_RESET=$'\033[0m'
  else
    C_RED="" C_GREEN="" C_PURPLE="" C_GRAY="" C_RESET=""
  fi
  I_OK="${C_GRAY}[${C_GREEN} OK ${C_GRAY}]${C_RESET} "
  I_INFO="${C_GRAY}[${C_PURPLE} INFO ${C_GRAY}]${C_RESET} "
  I_ERR="${C_GRAY}[${C_RED} ERROR ${C_GRAY}]${C_RESET} "
}
_log() {
  local style=$1
  shift
  printf '%s%s%s\n' "$style" "$*" "$C_RESET"
}
log_ok() { _log "$I_OK" "$@"; }
log_info() { _log "$I_INFO" "$@"; }
log_err() { _log "$I_ERR" "$@" >&2; }

# Call Main Function with args
main "$@"
