#!/usr/bin/env bash

# --                             -- #
# --     INSTALLATION SCRIPT     -- #
# --                             -- #

# [0] Main Function
function main() {
  # Call Core Functions
  load_utils "$username" "$repo_name" # Called with variables defined in the Install-Command
  { read_config && echo -e "${I_OK}Config File read"; } || { echo -e "${I_ERR}Failed to read Config File"; exit 1; }
  { prerequisites && echo -e "${I_OK}Prerequesites satisfied"; } || { echo -e "${I_ERR}Failed to ensure that prerequesites are satisfied"; exit 1; }
  { install && echo -e "${I_OK}Installation completed"; } || { echo -e "${I_ERR}Installation failed"; exit 1; }
}

# [1] Curl & Source Utility Script from Remote Repository
function load_utils(){
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
  source "$TMP_SCRIPT" && echo -e "${I_OK}Utility Script sourced" || { echo -e "${I_ERR}Failed to source Utility Script: $TMP_SCRIPT"; exit 1; }  
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
    linux) { sudo dnf install -y git && echo -e "${I_OK}Installation succeeded: git" ;} || { echo -e "${I_ERR}Installation failed: git"; return 1; } ;;
    macos) { brew install git && echo -e "${I_OK}Installation succeeded: git" ;} || { echo -e "${I_ERR}Installation failed: git"; return 1; } ;;
    windows) echo -e "${I_ERR}Windows not supported yet"; return 1 ;;
    unsupported) echo -e "${I_ERR}Unsuported Operating System: $ONESETUP_SYSTEM_OS"; return 1 ;;
    esac
  fi
  # gum
  if ! command -v "gum" &>/dev/null; then
    case "$ONESETUP_SYSTEM_OS" in
    linux) { sudo dnf install -y "gum" && echo -e "${I_OK}Installation succeeded: gum" ;} || { echo -e "${I_ERR}Failed to install gum!"; return 1; } ;;
    macos) { brew install "gum" && echo -e "${I_OK}Installation succeeded: gum" ;} || { echo -e "${I_ERR}Failed to install gum!"; return 1; } ;;
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

  # Step 1: Remove installation directory if invalid/corrupted
  if [[ -d "$install_dir" ]]; then
    if ! git -C "$install_dir" rev-parse --git-dir >/dev/null 2>&1; then
      rm -rf "$install_dir" && \
      echo -e "${I_INFO}There was a broken installation at $install_dir. Deletion complete."
    fi
  fi

  # Step 2: Check for updates if repository already exists
  if [[ -d "$install_dir" ]]; then
    local local_sha remote_sha
    local_sha=$(git -C "$install_dir" rev-parse HEAD 2>/dev/null || echo "")
    remote_sha=$(git ls-remote "$repo_uri" HEAD 2>/dev/null | awk '{print $1}')
    # Compare local commit hash with latest remote
    if [[ -n "$local_sha" && -n "$remote_sha" ]]; then
      if [[ "$local_sha" != "$remote_sha" ]]; then
        echo -e "${I_WARN}Installation directory is outdated."
        echo -e "${I_INFO}Updating to latest version..."
        rm -rf "$install_dir" && git clone --depth 1 --single-branch "$repo_uri" "$install_dir"
      else
        echo -e "${I_OK}The installation directory is up-to-date with the remote (https://github.com/$repo_name)."
        echo -e "${I_INFO}Skipping installation..."
      fi
    else
      echo -e "${I_ERR}Failed to verify remote commit hash. Re-installing..."
      rm -rf "$install_dir" && git clone --depth 1 --single-branch "$repo_uri" "$install_dir"
    fi
  fi

  # Step 3: Perform fresh installation if directory doesn't exist
  if [[ ! -d "$install_dir" ]]; then
    echo -e "${I_INFO}No installation found for 'onesetup'. Installing to ${install_dir}..."
    git clone --depth 1 --single-branch "$repo_uri" "$install_dir" && echo -e "${I_OK}Installation complete!"
  fi

  # Step 4: Ensure permissions and deploy binaries
  ensure_directory "$install_dir" "755" "${ONESETUP_SYSTEM_USERNAME}:${ONESETUP_SYSTEM_USER_GROUP}" true
  ensure_directory "$bin_dir" "755" "${ONESETUP_SYSTEM_ROOT_USER}:${ONESETUP_SYSTEM_ADMIN_GROUP}"

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
