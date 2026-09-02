#!/usr/bin/env bash

# --                          -- #
# --     HELPER FUNCTIONS     -- #
# --                          -- #

# [Helper] Terminal Colors & Prompts
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
  export I_ERR="${C_BLACK}[${C_RED} ERROR ${C_BLACK}] ${C_RESET}"     # error
  export I_YN="${C_BLACK}[${C_BLUE} y/n ${C_BLACK}] ${C_RESET}"          # ask user for yes/no
  export I_ASK="${C_BLACK}[${C_BLUE} ? ${C_BLACK}] ${C_RESET}"           # ask user for anything
  export I_LOAD="${C_BLACK}[${C_BLUE} LOADING .. ${C_BLACK}] ${C_RESET}" # ask user for anything
}

# [Helper] Set Script Modes TODO: refactor this
function set_modes() {
  set -eo pipefail
  TOGGLE_SCRIPT_DEBUG_MODE="${TOGGLE_SCRIPT_DEBUG_MODE:-0}"
  if [[ "$TOGGLE_SCRIPT_DEBUG_MODE" -eq 1 ]]; then
    set -x
    echo -e "${I_OK}Running Script in Debug Mode"
  fi
}

# [Helper] Detect Operating System
function detect_os() {
  local platform
  platform=$(uname -s)
  case "$platform" in
    Linux*) echo "linux" ;;
    Darwin*) echo "macos" ;;
    CYGWIN* | MINGW* | MSYS*) echo "windows" ;;
    *) echo "unsupported" ;;
  esac
}

# [Helper] Ensure Directory presence with right permissions
function ensure_directory() {
  local target_dir="$1" desired_perms="$2" desired_ownership="$3" recursive="${4:-false}"
  local chown_flag=""
  [[ "$recursive" == "true" ]] && chown_flag="-R"
  # Create Directory & set permissions if not present yet
  if [[ ! -d "$target_dir" ]]; then
    sudo mkdir -p "$target_dir"
    sudo chown $chown_flag "$desired_ownership" "$target_dir"
    sudo chmod "$desired_perms" "$target_dir"
  else
    # Check Permissions on existing Directory
    local current_owner current_perms
    if [[ "$(detect_os)" == "macos" ]]; then
      current_owner=$(stat -f "%Su:%Sg" "$target_dir")
      current_perms=$(stat -f "%Lp" "$target_dir")
    else
      current_owner=$(stat -c "%U:%G" "$target_dir")
      current_perms=$(stat -c "%a" "$target_dir")
    fi
    # Set Permissions on existing Directory
    [[ "$current_owner" != "$desired_ownership" ]] && sudo chown $chown_flag "$desired_ownership" "$target_dir"
    [[ "$current_perms" != "$desired_perms" ]] && sudo chmod "$desired_perms" "$target_dir"
  fi
}

# --                        -- #
# --     CORE FUNCTIONS     -- #
# --                        -- #

# [0] Main Function
function main() {
  # Call Helper Functions 
  tty_styles || echo -e "${I_WARN}Failed to load TTY Styles."
  set_modes || echo -e "${I_WARN}Failed to set Script Modes."
  # Call Core Functions
  load_env "$username" "$repo_name" # Called with variables defined in the Install-Command
  { read_config && echo -e "${I_OK}Config File read"; } || { echo -e "${I_ERR}Failed to read Config File"; exit 1; }
  { prerequisites && echo -e "${I_OK}Prerequesites satisfied"; } || { echo -e "${I_ERR}Failed to ensure that prerequesites are satisfied"; exit 1; }
  { install && echo -e "${I_OK}Installation completed"; } || { echo -e "${I_ERR}Installation failed"; exit 1; }
}

# [1] Curl & Source Environment Script that has the read_config() function
function load_env(){
  local username="$1"
  local repo_name="$2"

  if [[ -z "$username" || -z "$repo_name" ]]; then
    echo -e "${I_ERR}Username or Repository Name missing. Please pass these directly in the Install-Command"
    echo -e "${I_INFO}See: README.md"
    exit 1
  else
    echo -e "${I_INFO}Github Repository github.com/"${username}/${repo_name}" will be used for Installation."
  fi

  TMP_SCRIPT=$(mktemp)
  trap 'rm -f "$TMP_SCRIPT"' EXIT
  curl -fsSL "https://raw.githubusercontent.com/${username}/${repo_name}/main/scripts/env.sh" -o "$TMP_SCRIPT"
  source "$TMP_SCRIPT" && echo -e "${I_OK}Environment Script sourced" || { echo -e "${I_ERR}Failed to source Environment Script: $TMP_SCRIPT"; exit 1; }  
}

# [2] Ensure prerequisites are satisfied
function prerequisites() {
  # pkg-manager 
  case "$ONESETUP_SYSTEM_OS" in
    linux)
      # TODO: logic to install & keep pkg manager up-to-date
      ;;
    macos)
      if ! command -v "brew" &>/dev/null; then
        # TODO: automatic installation of homebrew if possible
        echo -e "${I_ERR}Homebrew not available. Please install from 'https://brew.sh' & re-run script"
        return 1
      fi
      ;;
    windows)
      # TODO: logic to install & keep pkg manager up-to-date
      ;;
    unsupported)
      echo -e "${I_ERR}Unsuported Operating System: $ONESETUP_SYSTEM_OS"
      return 1
      ;;
  esac

  # git
  if ! command -v "git" &>/dev/null; then
    case "$ONESETUP_SYSTEM_OS" in
    linux) sudo dnf install -y git ;;
    macos) brew install git ;;
    windows) echo -e "${I_WARN}Windows not supported yet"; return 1 ;;
    unsupported) echo -e "${I_ERR}Unsuported Operating System: $ONESETUP_SYSTEM_OS"; return 1 ;;
    esac
  fi
  # gum
  if ! command -v "gum" &>/dev/null; then
    case "$ONESETUP_SYSTEM_OS" in
    linux) { sudo dnf install -y "gum" && echo -e "${I_OK}gum installed!" ;} || { echo -e "${I_ERR}failed to install gum!"; return 1; } ;;
    macos) { brew install "gum" && echo -e "${I_OK}gum installed!" ;} || { echo -e "${I_ERR}failed to install gum!"; return 1; } ;;
    windows) echo -e "${I_WARN}Windows not supported yet"; return 1 ;;
    unsupported) echo -e "${I_ERR}Unsuported Operating System: $ONESETUP_SYSTEM_OS"; return 1 ;;
    esac
  fi
}

# [3] Run Installation
function install() {
  local repo_name="${ONESETUP_REMOTE_USERNAME}/${ONESETUP_REMOTE_PROJECT_REPO}"
  local install_dir="$ONESETUP_SYSTEM_INSTALL_DIR"
  local bin_dir="$ONESETUP_SYSTEM_BIN_DIR"
  local repo_uri="$ONESETUP_PROJECT_REPO_URI"

  # Check if installation directory is a git repository
  if [[ -d "$install_dir" ]]; then
    if ! git -C "$install_dir" rev-parse --git-dir >/dev/null 2>&1; then
      rm -rf "$install_dir" && \
      echo -e "${I_INFO}There was a broken installation at $install_dir. Deletion complete."
    fi
  fi

  # Check if installation directory is up-to-date
  if [[ -d "$install_dir" ]]; then
    git -C "$install_dir" fetch
    local behind_count
    local ahead_count
    behind_count=$(git -C "$install_dir" rev-list --count HEAD..@{u})
    ahead_count=$(git -C "$install_dir" rev-list --count @{u}..HEAD)
    if (($behind_count > 0)) || (($ahead_count > 0)); then
      if (($behind_count > 0)) && (($ahead_count > 0)); then
        echo -e "${I_WARN}The installation directory is $behind_count commits behind and $ahead_count commits ahead of the remote (https://github.com/$repo_name)."
        echo -e "${I_ERR}Please Check! Exiting.."; exit 1
      elif (($ahead_count > 0)); then
        echo -e "${I_WARN}The installation directory is $ahead_count commits ahead of the remote (https://github.com/$repo_name)."
        echo -e "${I_ERR}Please Check! Exiting.."; exit 1
      elif (($behind_count > 0)); then
        echo -e "${I_INFO}The installation directory is $behind_count commits behind of the remote (https://github.com/$repo_name)."
        echo -e "${I_INFO}Updating.."
        sudo rm -rf "$install_dir" && sudo git clone "$repo_uri" "$install_dir"
      fi
    else
      echo -e "${I_WARN}The installation directory is up-to-date with the remote (https://github.com/$repo_name)."
      echo -e "${I_INFO}Skipping installation.."
    fi
  fi

  # Install only if directory is empty.
  if [[ ! -d "$install_dir" ]]; then
    echo -e "${I_INFO}No Installation found for 'onesetup'. Installing to ${install_dir} .."
    sudo git clone "$repo_uri" "$install_dir" && echo -e "${I_OK}Installation complete!"
  fi

  # Ensure install directory has correct permissions (recursive)
  ensure_directory "$install_dir" "755" "${ONESETUP_SYSTEM_USERNAME}:${ONESETUP_SYSTEM_USER_GROUP}" true

  # Ensure bin directory exists with correct permissions
  ensure_directory "$bin_dir" "755" "${ONESETUP_SYSTEM_ROOT_USER}:${ONESETUP_SYSTEM_ADMIN_GROUP}"

  # Rollout executables to bin_dir
  for file in "${install_dir}"/bin/*; do
    if [[ -f "$file" ]]; then
      local filename
      filename=$(basename "$file")
      sudo cp -f "$file" "${bin_dir}/" && echo -e "${I_OK}${C_GREEN}$filename${C_RESET} copied to ${C_GREEN}${bin_dir}${C_RESET}" || { echo -e "${I_ERR}Failed to copy ${C_RED}$filename${C_RESET} to ${C_RED}${bin_dir}${C_RESET}"; return 1; }
    fi
  done
}

# Call Main Function with args
main "$@"
