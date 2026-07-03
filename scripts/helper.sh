#!/usr/bin/env bash
# (1) Set Shell-Script Modes
function set_modes() {
  # Exit on error & pipe failures
  set -eo pipefail
  # Prompt whether script should run in debug-mode when $TOGGLE_SCRIPT_DEBUG_MODE env var is not set.
  if [[ -z $TOGGLE_SCRIPT_DEBUG_MODE ]]; then
    export TOGGLE_SCRIPT_DEBUG_MODE=0 # disabled by default
  fi
  if [[ $TOGGLE_SCRIPT_DEBUG_MODE -eq 1 ]]; then
    set -x && echo -e "${I_OK}Running Script in Debug Mode"
  fi
}

# (2) Set TTY Style Variables (colors, prompts, ..)
function tty_styles() {
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

}
# (3) Get Dynamic Directory Paths
function get_paths() {
  THIS_FILE=$(realpath "$0")
  THIS_DIR=$(dirname "$(realpath "$0")")
  # Git Directory Paths
  if git rev-parse --git-dir >/dev/null 2>&1; then
    REPO_ROOT="$(git rev-parse --show-toplevel)"
  else
    echo -e "${I_WARN}The REPO_ROOT variable can only be detected inside of a git repository."
  fi
  # Export Variables
  export THIS_FILE
  export THIS_DIR
  export REPO_ROOT
}

# (4) Detect Operating System
function detect_os() {
  local platform
  platform=$(uname -s)

  case "$platform" in
  Linux*)
    export OS="linux"
    ;;
  Darwin*)
    export OS="macos"
    ;;
  CYGWIN* | MINGW* | MSYS*)
    export OS="windows"
    ;;
  *)
    export OS="unsupported"
    ;;
  esac
}

# *(5) Load Env Files
# usage: load_env_file "/path/to/.env" "/path/to/.env2" "/path/to/.env3" ...
function load_env_file() {
  # Check if .env files provided
  if [ $# -eq 0 ]; then
    echo -e "${I_ERR}No .env files provided."
    echo -e "${I_INFO}Usage: load_env_file 'path/to/.env' 'path/to/.env2' 'path/to/.env3'"
    return 1
  fi
  # Counter for provided, existing & missing env file paths
  local count_args=0     # overall .env file paths passed to the function
  local count_existing=0 # existing .env file paths
  local count_missing=0  # non-existing .env file paths
  # Source env files
  for env_file in "$@"; do
    ((count_args++))
    if [ -f "$env_file" ]; then
      ((count_existing++))
      source "$env_file" && echo -e "${I_OK}Sourced: ${env_file}!" || echo -e "${I_ERR}Failed to Source: ${env_file}!"
    else
      ((count_missing++))
    fi
  done
  echo -e "${I_INFO}You passed ${FG_BLUE}$count_args${S_RESET} .env file where ${FG_GREEN}$count_existing${S_RESET} exist and ${FG_RED}$count_missing${S_RESET} don't exist."

  # Return exit-code
  if [ $count_missing -gt 0 ]; then
    return 1 # failure
  else
    return 0 # success
  fi
}

# Default Function Calls
set_modes || echo -e "${I_WARN}Failed to set Script Modes."
tty_styles || echo -e "${I_WARN}Failed to load TTY Styles."
get_paths || echo -e "${I_WARN}Failed to load Dynamic Directory Paths."
detect_os || echo -e "${I_WARN}Failed to detect Operating System."
