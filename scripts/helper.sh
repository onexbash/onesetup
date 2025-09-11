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
}

function load_styles() {
  # Export Style Variables
  export S_RESET="\e[0m"
  export S_BOLD="\e[1m"
}

# Load Prompt Style Variables
function load_prompts() {
  # ok
  export I_OK="${FG_BLACK}[${FG_GREEN}  OK  ${FG_BLACK}] ${S_RESET}"       
  # warning
  export I_WARN="${FG_BLACK}[${FG_YELLOW} WARNING ${FG_BLACK}] ${S_RESET}" 
  # error
  export I_ERR="${FG_BLACK}[${FG_RED} ERROR ${FG_BLACK}] ${S_RESET}"    
  # info
  export I_INFO="${FG_BLACK}[${FG_MAGENTA} INFO ${FG_BLACK}] ${S_RESET}"    
  # do
  export I_DO="${FG_BLACK}[${FG_MAGENTA}  ...  ${FG_BLACK}] ${S_RESET}"     
  # ask user for anything
  export I_ASK="${FG_BLACK}[${FG_BLUE} ? ${FG_BLACK}] ${S_RESET}"          
  # ask user for yes or no
  export I_ASK_YN="${FG_BLACK}[${FG_BLUE} [Y/N] ${FG_BLACK}] ${S_RESET}"   
}

# -- SET SCRIPT MODES -- #
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

# -- GET DYNAMIC PATHS -- #
function get_paths() {
  export THIS_FILE=$(realpath "$0")
  export THIS_DIR=$(dirname "$(realpath "$0")")
  if git rev-parse --git-dir > /dev/null 2>&1; then
    export REPO_ROOT="$(git rev-parse --show-toplevel)"
  fi
}

# -- LOAD ENV FILES -- #
# usage: load_env_file "/path/to/.env" "/path/to/.env2" "/path/to/.env3" ...
function load_env_file() {
  # Check if .env files provided
  if [ $# -eq 0 ]; then
    echo -e "${I_ERR}No .env files provided."
    echo -e "${I_INFO}Usage: load_env_file 'path/to/.env' 'path/to/.env2' 'path/to/.env3'"
    return 1
  fi
  # Counter for provided, existing & missing env file paths
  local count_args=0 # overall .env file paths passed to the function
  local count_existing=0 # existing .env file paths
  local count_missing=0 # non-existing .env file paths
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
  echo -e "${I_INFO}You passed ${FG_BLUE}$count_args${RESET} .env file where ${FG_GREEN}$count_existing${RESET} exist and ${FG_RED}$count_missing${RESET} don't exist."
  
  # Return exit code
  if [ $count_missing -gt 0 ]; then
    return 1 # failure
  else
    return 0 # success
  fi
}


# -- DETECT OPERATING SYSTEM -- #
function detect_os() {
  case "$(uname -s)" in
    Linux*)  echo "linux";;
    Darwin*) echo "macos";;
    *)       echo "unknown";;
  esac
}
function detect_linux_dist() {
  if [ -f "/etc/os-release" ]; then
    source "/etc/os-release"
    echo "$NAME" # function returns only the linux distribution name
  fi
}
