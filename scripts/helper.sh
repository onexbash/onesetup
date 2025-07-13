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
  export I_ERR="${C_BLACK}[${C_YELLOW} ERROR ${C_BLACK}] ${C_RESET}"    # error
  export I_INFO="${C_BLACK}[${C_PURPLE} INFO ${C_BLACK}] ${C_RESET}"    # info
  export I_DO="${C_BLACK}[${C_PURPLE}  ...  ${C_BLACK}] ${C_RESET}"     # do
  export I_DONE="${C_BLACK}[${C_GREEN} DONE ${C_BLACK}] ${C_RESET}"     # done
  export I_ASK="${C_BLACK}[${C_BLUE} ? ${C_BLACK}] ${C_RESET}"          # ask user for anything
  export I_ASK_YN="${C_BLACK}[${C_BLUE} [Y/N] ${C_BLACK}] ${C_RESET}"   # ask user for yes or no
  return 0
}

function set_modes() {
  # Exit on error & pipe failures
  set -eo pipefail
  # Prompt whether script should run in debug-mode when $TOGGLE_SCRIPT_DEBUG env var is not set.
  if [[ -z $TOGGLE_SCRIPT_DEBUG ]]; then
    read -p "$(echo -e "${I_ASK_YN}Run Script in Debug Mode? ")" -r answer
      case "$answer" in
        [Yy]) TOGGLE_SCRIPT_DEBUG=1;;
        *)    TOGGLE_SCRIPT_DEBUG=0;;
    esac
    if [[ $TOGGLE_SCRIPT_DEBUG -eq 1 ]]; then
      set -x && echo -e "${I_OK}Running Script in Debug Mode"
    fi
  fi
}
