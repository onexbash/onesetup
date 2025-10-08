#!/usr/bin/env bash
# (1) load_colors
function load_colors() {
  # Define Ansi Color Codes
  local -A colors
  colors=(
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
  # Define Ansi Control Codes
  local -A controls
  controls=(
    ["foreground"]="38"
    ["background"]="48"
    ["colorspace"]="5"
  )

  # Construct Ansi Escape Sequence
  get_ansi_sequence() {
    local type="$1"  # "fg" or "bg"
    local color="$2" # color name from colors array
    echo "\e[${controls[$type]};${controls["colorspace"]};${colors[$color]}m"
  }

  # Construct & Export Color Variables
  for color in "${!colors[@]}"; do
    # Format Color Name to uppercase
    local color_fmt
    color_fmt=$(echo "$color" | tr '[:lower:]' '[:upper:]')
    # Export Foreground Colors - usage: `echo -e "${FG_RED}red text"`
    export "FG_${color_fmt}"="$(get_ansi_sequence "foreground" "$color")"
    # Export Background Colors - usage: `echo -e "${BG_RED}red background"`
    export "BG_${color_fmt}"="$(get_ansi_sequence "background" "$color")"
  done
}

# (2) Load Font Style Variables
function load_styles() {
  # Define Variables
  S_RESET="\e[0m"
  S_BOLD="\e[1m"
  # Export Variables
  export S_RESET
  export S_BOLD
}

# (3) Load Prompt Variables
function load_prompts() {
  # Define Variables
  # ok
  I_OK="${FG_BLACK}[${FG_GREEN}  OK  ${FG_BLACK}] ${S_RESET}"
  # warning
  I_WARN="${FG_BLACK}[${FG_YELLOW} WARNING ${FG_BLACK}] ${S_RESET}"
  # error
  I_ERR="${FG_BLACK}[${FG_RED} ERROR ${FG_BLACK}] ${S_RESET}"
  # info
  I_INFO="${FG_BLACK}[${FG_MAGENTA} INFO ${FG_BLACK}] ${S_RESET}"
  # do
  I_DO="${FG_BLACK}[${FG_MAGENTA}  ...  ${FG_BLACK}] ${S_RESET}"
  # ask user for anything
  I_ASK="${FG_BLACK}[${FG_BLUE} ? ${FG_BLACK}] ${S_RESET}"
  # ask user for yes or no
  I_ASK_YN="${FG_BLACK}[${FG_BLUE} [Y/N] ${FG_BLACK}] ${S_RESET}"
  # Export Variables
  export I_OK
  export I_WARN
  export I_ERR
  export I_INFO
  export I_DO
  export I_ASK
  export I_ASK_YN
}

# (4) Set Shell-Script Modes
function set_modes() {
  # Exit on error & pipe failures
  set -eo pipefail
  # Prompt whether script should run in debug-mode when $TOGGLE_SCRIPT_DEBUG_MODE env var is not set.
  if [[ -z $TOGGLE_SCRIPT_DEBUG_MODE ]]; then
    read -p "$(echo -e "${I_ASK_YN}Run Script in Debug Mode? ")" -r answer
    case "$answer" in
    [Yy]) TOGGLE_SCRIPT_DEBUG_MODE=1 ;;
    *) TOGGLE_SCRIPT_DEBUG_MODE=0 ;;
    esac
    if [[ $TOGGLE_SCRIPT_DEBUG_MODE -eq 1 ]]; then
      set -x && echo -e "${I_OK}Running Script in Debug Mode"
    fi
  fi
}

# (4) Set Shell-Script Modes
function get_paths() {
  THIS_FILE=$(realpath "$0")
  THIS_DIR=$(dirname "$(realpath "$0")")
  REPO_ROOT="$(git rev-parse --show-toplevel)"
  # Export Default Path Variables
  export THIS_FILE
  export THIS_DIR
  # Export Git Path Variables
  if git rev-parse --git-dir >/dev/null 2>&1; then
    export REPO_ROOT
  else
    echo -e "${I_WARN}The REPO_ROOT variable can only be detected inside of a git repository."
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

# -- DETECT OPERATING SYSTEM -- #
function detect_os() {
  case "$(uname -s)" in
  Linux*) echo "linux" ;;
  Darwin*) echo "macos" ;;
  *) echo "unknown" ;;
  esac
}

# Call Default Functions
load_colors && load_styles && load_prompts && set_modes
