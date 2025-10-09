#!/usr/bin/env bash
# (1) Set Shell-Script Modes
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

# (2) Set TTY Style Variables (colors, prompts, ..)
function tty_styles() {
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
  # Define Font Styles
  local -A styles
  styles=(
    ["reset"]="\e[0m"
    ["bold"]="\e[1m"
    ["dim"]="\e[2m"
    ["italic"]="\e[3m"
    ["underline"]="\e[4m"
    ["blink"]="\e[5m"
    ["inverse"]="\e[7m"
    ["hidden"]="\e[8m"
    ["strikethrough"]="\e[9m"
  )
  # Define Prompt Colors & Contents
  local -A prompts
  prompts=(
    ["ok"]="green|OK"
    ["warn"]="yellow|WARN"
    ["err"]="red|ERR"
    ["info"]="magenta|INFO"
    ["do"]="blue|.."
    ["ask"]="cyan|?"
    ["ask_yn"]="cyan|[Y/N]"
    ["list"]="cyan|-"
  )

  # Construct & Export Color Variables
  load_colors() {
    # Construct Ansi Escape Sequence
    get_ansi_sequence() {
      local type="$1"  # "fg" or "bg"
      local color="$2" # color name from colors array
      echo "\e[${controls[$type]};${controls["colorspace"]};${colors[$color]}m"
    }
    # Export Variables
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

  # Construct & Export Font Style Variables
  load_font_styles() {
    for style in "${!styles[@]}"; do
      # transform name to uppercase
      local style_fmt="${style^^}"
      # construct & export based on $styles array
      export "S_${style_fmt}"="${styles[$style]}"
    done
  }

  # Define & Export Prompt Variables
  load_prompts() {
    for prompt in "${!prompts[@]}"; do
      local color
      local color_fmt
      local content
      local value
      # read values from prompts array (seperated by `|`)
      IFS='|' read -r color content <<<"${prompts[$prompt]}"
      color_fmt="FG_${color^^}"
      # construct & export based on $prompts array
      value="${FG_BLACK}[${!color_fmt}  ${content}  ${FG_BLACK}] ${S_RESET}"
      export "I_${prompt^^}"="${value}"
    done
  }

  # Sub-Function Calls
  load_colors
  load_font_styles
  load_prompts
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
