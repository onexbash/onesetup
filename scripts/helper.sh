#!/usr/bin/env bash
function load_colors() {
  # -- DEFINE ANSI CODES -- #
  declare -A colorcodes
  colorcodes=(
    ["black"]="0"
    ["red"]="1" 
    ["green"]="2"
    ["yellow"]="3"
    ["blue"]="4"
    ["magenta"]="5"
    ["cyan"]="6"
    ["white"]="7"
    ["gray"]="8"
  )

  # Control Codes
  local foreground="38"
  local background="48"
  local colorspace="5" # 5) 256 Colors | 2) RGB Colors
  
  # -- CONSTRUCT ANSI ESCAPE SEQUENCE -- #
  get_ansi_sequence() {
    local type="$1"    # "fg" or "bg"
    local color="$2"   # color name from colorcodes array

    if [[ "$type" == "fg" ]]; then
      type="$foreground"
    elif [[ "$type" == "bg" ]]; then
      type="$background"
    fi
    # return constructed ansi escape sequence
    echo "\e[${type};${colorspace};${colorcodes[$color]}m"
  }
 
  # -- EXPORT VARIABLES -- #
  # Export Color Variables
  for color in "${!colorcodes[@]}"; do
    # Foreground Colors
    # usage: `echo -e "${FG_BLUE}blue text"`
    export "FG_${color^^}"="$(get_ansi_sequence "fg" "$color")"
    # Background Colors
    # usage: `echo -e "${BG_BLUE}blue background"`
    export "BG_${color^^}"="$(get_ansi_sequence "bg" "$color")"
  done 
  # Export Style Variables
  export RESET="\e[0m"
  export BOLD="\e[1m"
}

# Load Prompt Style Variables
function load_prompt_styles() {
  # ok
  export I_OK="${FG_BLACK}[${FG_GREEN}  OK  ${FG_BLACK}] ${RESET}"       
  # warning
  export I_WARN="${FG_BLACK}[${FG_YELLOW} WARNING ${FG_BLACK}] ${RESET}" 
  # error
  export I_ERR="${FG_BLACK}[${FG_RED} ERROR ${FG_BLACK}] ${RESET}"    
  # info
  export I_INFO="${FG_BLACK}[${FG_PURPLE} INFO ${FG_BLACK}] ${RESET}"    
  # do
  export I_DO="${FG_BLACK}[${FG_PURPLE}  ...  ${FG_BLACK}] ${RESET}"     
  # ask user for anything
  export I_ASK="${FG_BLACK}[${FG_BLUE} ? ${FG_BLACK}] ${RESET}"          
  # ask user for yes or no
  export I_ASK_YN="${FG_BLACK}[${FG_BLUE} [Y/N] ${FG_BLACK}] ${RESET}"   
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

