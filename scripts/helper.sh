#!/usr/bin/env bash
# -- -- -- -- -- -- -- -- -- -- #
# --      HELPER SCRIPT      -- #
# -- -- -- -- -- -- -- -- -- -- #
# this script loads prompt stylings, sets some options
# and provides reusable functions that can be sourced by other scripts.

# -- PROMPT STYLINGS -- #
function load_stylings(){
  export C_BLACK='\033[1;30m'
  export C_RED='\033[1;31m'
  export C_GREEN='\033[1;32m'
  export C_YELLOW='\033[1;33m'
  export C_BLUE='\033[1;34m'
  export C_PURPLE='\033[1;35m'
  export C_CYAN='\033[1;36m'
  export C_WHITE='\033[1;37m'
  export C_GRAY='\033[1;30m'
  export C_RESET='\033[0m'
  export I_OK="${C_BLACK}[${C_GREEN}  OK  ${C_BLACK}] ${C_RESET}"       # ok
  export I_WARN="${C_BLACK}[${C_YELLOW} WARNING ${C_BLACK}] ${C_RESET}" # warning
  export I_ERR="${C_BLACK}[${C_RED} ERROR ${C_BLACK}] ${C_RESET}"    # error
  export I_INFO="${C_BLACK}[${C_PURPLE} INFO ${C_BLACK}] ${C_RESET}"    # info
  export I_DO="${C_BLACK}[${C_PURPLE}  ...  ${C_BLACK}] ${C_RESET}"     # do
  export I_DONE="${C_BLACK}[${C_GREEN} DONE ${C_BLACK}] ${C_RESET}"     # done
  export I_ASK="${C_BLACK}[${C_BLUE} ? ${C_BLACK}] ${C_RESET}"          # ask user for anything
  export I_ASK_YN="${C_BLACK}[${C_BLUE} [Y/N] ${C_BLACK}] ${C_RESET}"   # ask user for yes or no
  return 0
}

# Set Script modes (exit behaviour etc.)
function set_modes() {
  # Exit on error & pipe failures
  set -eo pipefail
  # Prompt whether script should run in debug-mode when $TOGGLE_SCRIPT_DEBUG_MODE env var is not set.
  if [[ -z $TOGGLE_SCRIPT_DEBUG_MODE ]]; then
    read -p "$(echo -e "${I_ASK_YN}Run Script in Debug Mode? ")" -r answer
      case "$answer" in
        [Yy]) TOGGLE_SCRIPT_DEBUG_MODE=1;;
        *)    TOGGLE_SCRIPT_DEBUG_MODE=0;;
    esac
    if [[ $TOGGLE_SCRIPT_DEBUG_MODE -eq 1 ]]; then
      set -x && echo -e "${I_OK}Running Script in Debug Mode"
    fi
  fi
}

# Get Working Directory where a script is located.
function get_script_pwd() {
  SOURCE="${BASH_SOURCE[0]}"
  while [ -L "$SOURCE" ]; do
    DIR="$(cd -P -- "$(dirname -- "$SOURCE")" >/dev/null 2>&1 && pwd)"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
  done
  # this directory
  THIS_DIR="$(cd -P -- "$(dirname -- "$SOURCE")" >/dev/null 2>&1 && pwd)" && export THIS_DIR="$THIS_DIR"
  # parent directory of this directory
  PARENT_DIR="$(dirname "$THIS_DIR")" && export PARENT_DIR="$PARENT_DIR"
  # repository root (only works inside of a git repository)
  REPO_ROOT="$(git rev-parse --show-toplevel)" && export REPO_ROOT="$REPO_ROOT"
}

# Accepts a directory as parameter & loads variables from all .env files inside of it.
# usage: load_env_file "/path/to/project/directory"
function load_env_file() {
  local env_dir="$1"
  if [ -f "$env_dir/.env" ]; then
    set -a
    source "$env_dir/.env"
    set +a
  else
    echo "No .env file found in $env_dir" >&2
  fi
}

function load_tools(){
  # gum
  if ! command -v gum >/dev/null 2>&1; then
    echo -e "${I_DO}Installing gum"
    brew install gum
  fi
}


function print_sysinfo() {
  HOSTNAME="$(hostname -s)"
  OS="$(sw_vers -productName)"
  OS_VERSION="$(sw_vers -productVersion)"
  IFACE="$(route -n get default 2>/dev/null | awk '/interface:/{print $2; exit}')"
  
  IPV4=""
  if [[ -n "${IFACE}" ]]; then
    if ipconfig getifaddr "$IFACE" >/dev/null 2>&1; then
      IPV4="$(ipconfig getifaddr "$IFACE")"
    else
      IPV4="$(ifconfig "$IFACE" 2>/dev/null | awk '$1=="inet"{print $2; exit}')"
    fi
  fi
  echo -e "${I_INFO}HOSTNAME: $HOSTNAME"
  echo -e "${I_INFO}OS: $OS"
  echo -e "${I_INFO}OS Version: $OS_VERSION"
  echo -e "${I_INFO}Network Interface: ${IFACE:-unknown}${IPV4:+ ($IPV4)}"
}

