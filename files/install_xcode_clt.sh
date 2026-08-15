#!/usr/bin/env bash

# -- XCode CommandLineTools: Automatic Installation & Upgrading Script -- #
# NOTE: called by ansible playbook (./pre_tasks/xcode.yml)

# Main Function
function main(){
  local status=0

  set_modes  || echo -e "${I_WARN}Failed to set Script Modes."
  tty_styles || echo -e "${I_WARN}Failed to load TTY Styles."

  if ! install; then
    echo -e "${I_ERR}Failed to install/update XCode CommandLineTools"
    status=1
  fi

  if [[ $status -eq 0 ]]; then
    if ! post_install; then
      echo -e "${I_ERR}Failed to run post-installation"
      status=1
    fi
  else
    echo -e "${I_WARN}Skipping post-installation because install failed."
  fi

  exit "$status"
}

# Helper: Set Script Modes
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

# Helper: TTY Styles (colors, prompts, ..)
function tty_styles() {
  # Terminal Colors
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
  # Info Prompts
  export I_SKIP="${C_BLACK}[${C_CYAN} SKIPPING ${C_BLACK}] ${C_RESET}"   # skipping
  export I_WARN="${C_BLACK}[${C_YELLOW} WARNING ${C_BLACK}] ${C_RESET}"  # warning
  export I_OK="${C_BLACK}[${C_GREEN}  OK  ${C_BLACK}] ${C_RESET}"        # ok
  export I_INFO="${C_BLACK}[${C_PURPLE} INFO ${C_BLACK}] ${C_RESET}"     # info
  export I_ERR="${C_BLACK}[${C_YELLOW} ERROR ${C_BLACK}] ${C_RESET}"     # error
  export I_YN="${C_BLACK}[${C_BLUE} y/n ${C_BLACK}] ${C_RESET}"          # ask user for yes/no
  export I_ASK="${C_BLACK}[${C_BLUE} ? ${C_BLACK}] ${C_RESET}"           # ask user for anything
  export I_LOAD="${C_BLACK}[${C_BLUE} LOADING .. ${C_BLACK}] ${C_RESET}" # ask user for anything
}

# Returns latest CLT update label offered by softwareupdate (empty if none)
# NOTE: sort -V sorts whole lines; assumes all matched labels share the same prefix ("Command Line Tools for Xcode-")
# If Apple changes the prefix, this will break or at least not reliably pick the label with the latest version
function get_latest_clt_label(){
  local flagfile="$1"
  touch "$flagfile"
  local label
  label=$(softwareupdate -l 2>/dev/null \
    | grep -oE 'Label: [^,]+' \
    | sed 's/^Label: //' \
    | grep -i 'Command Line Tools' \
    | sort -V \
    | tail -n1)
  echo "$label"
}

# Extracts the version from the CLT label returned by softwareupdate
# e.g. "Command Line Tools for Xcode-15.3" -> "15.3"
function label_version(){
  echo "$1" | sed -E 's/.*-([0-9]+(\.[0-9]+)*)$/\1/'
}

# Compares installed version with latest version from the label: true if $1 >= $2 (version compare)
function versionIsLatest(){
  [[ "$1" == "$(printf '%s\n%s' "$1" "$2" | sort -V | tail -n1)" ]]
}

# Post Installation Functionality
function post_install(){
  local path_current path_expected
  path_expected="/Library/Developer/CommandLineTools"
  path_current="$(xcode-select --print-path 2>/dev/null || true)"

  # Guard: nothing to switch to if install didn't actually land
  if [[ ! -d "$path_expected" ]]; then
    echo -e "${I_ERR}Expected developer directory not found: $path_expected"
    return 1
  fi

  if [[ "$path_current" == "$path_expected" ]]; then
    echo -e "${I_OK}Active Developer Directory already set as expected: $path_expected"
    return 0
  fi

  if sudo xcode-select --switch "$path_expected"; then
    echo -e "${I_OK}Active Developer Directory was set to: $path_expected"
    return 0
  else
    echo -e "${I_WARN}Failed to set Active Developer Directory!"
    return 1
  fi
}

# Install XCode CommandLineTools
function install(){
  local flagfile="/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"
  trap 'rm -f "$flagfile"' RETURN

  local latest_label latest_version
  latest_label="$(get_latest_clt_label "$flagfile")"
  latest_version="$(label_version "$latest_label")"

  if xcode-select --print-path &>/dev/null; then
    local clt_path clt_version
    clt_path="$(xcode-select --print-path)"
    clt_version="$(pkgutil --pkg-info=com.apple.pkg.CLTools_Executables 2>/dev/null | awk -F': ' '/version/ {print $2}')"

    if [[ -z "$clt_version" ]]; then
      echo -e "${I_WARN}CLT appears installed at $clt_path but version could not be determined."
      return 1
    fi

    echo -e "${I_INFO}XCode CommandLineTools installed: $clt_path (v$clt_version)"

    if [[ -z "$latest_label" || -z "$latest_version" ]]; then
      echo -e "${I_OK}No update advertised by softwareupdate. Assuming up-to-date."
      return 0
    fi

    if versionIsLatest "$clt_version" "$latest_version"; then
      echo -e "${I_OK}Already up-to-date (v$clt_version)."
      return 0
    fi

    echo -e "${I_INFO}Updating CLT: v$clt_version -> v$latest_version"
    softwareupdate -i "$latest_label" --verbose
  else
    if [[ -z "$latest_label" ]]; then
      echo -e "${I_ERR}No CommandLineTools package found via softwareupdate."
      return 1
    fi
    echo -e "${I_INFO}Installing XCode CommandLineTools ($latest_version)"
    softwareupdate -i "$latest_label" --verbose
  fi
}

# Call Main Function with args
main "$@"
