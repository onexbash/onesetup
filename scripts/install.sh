#!/usr/bin/env bash

function main() {
  # Environment Variable Defaults (overwritten if set by user)
  if [[ -z "${ONESETUP_DIR:-}" ]]; then
    export ONESETUP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/onesetup"
  fi
  if [[ -z "${ONESETUP_REPO:-}" ]]; then
    export ONESETUP_REPO="onexbash/onesetup"
  fi
  if [[ -z "${DOTFILES_DIR:-}" ]]; then
    export DOTFILES_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles"
  fi
  if [[ -z "${DOTFILES_REPO:-}" ]]; then
    export DOTFILES_REPO="onexbash/dotfiles"
  fi
  if [[ -z "${ANSIBLE_DEBUG:-}" ]]; then
    export ANSIBLE_DEBUG=0
  fi

  # Variables
  local onesetup_uri_raw="https://raw.githubusercontent.com/${ONESETUP_REPO}/main"
  local onesetup_uri_https="https://github.com/${ONESETUP_REPO}.git"
  local onesetup_uri_ssh="git@github.com:${ONESETUP_REPO}.git"
  local dotfiles_uri_raw="https://raw.githubusercontent.com/${DOTFILES_REPO}/main"
  local dotfiles_uri_https="https://github.com/${DOTFILES_REPO}.git"
  local dotfiles_uri_ssh="git@github.com:${DOTFILES_REPO}.git"

  # Function Calls
  { helper && echo -e "${I_OK}Helper Script Loaded!"; } || echo -e "${I_WARN}Failed to load Helper Script from [$onesetup_uri_raw]"
  { prerequisites && echo -e "${I_OK}Prerequesites satisfied!"; } || echo -e "${I_WARN}Failed to ensure that prerequesites are satisfied."
  { install && echo -e "${I_OK}Onesetup Installed"; } || { echo -e "${I_ERR}Failed to install Onesetup." && exit 1; }
}

# Load Helper Script
function helper() {
  # Ensure $TMPDIR is set
  export TMPDIR="${TMPDIR:-/tmp}"
  # Create temp dir
  local tmp_dir
  tmp_dir=$(mktemp --directory --tmpdir "onesetup-XXXXXX")
  echo "tmp_dir: $tmp_dir"
  # Curl helper script from repository & store as tmp file
  curl -fs "$onesetup_uri_raw/scripts/helper.sh" -o "$tmp_dir/helper.sh"
  # Source helper script
  { source "$tmp_dir/helper.sh" && echo -e "${I_OK}Helper Script Loaded."; } || { echo -e "${I_ERR}Failed to load Helper Script. Please ensure your installation was correct." && exit 1; }
  sudo rm -rf "$tmp_dir" || echo -e "${I_WARN}Failed to cleanup temp directory: $tmp_dir"
}

# Ensure prerequisites are satisfied
function prerequisites() {
  # homebrew
  if [[ "$OS" = "macos" ]]; then
    if ! command -v "brew" &>/dev/null; then
      echo -e "${I_ERR}Homebrew not available. Please install from 'https://brew.sh' & re-run script"
    fi
  fi
  # git
  if ! command -v "git" &>/dev/null; then
    case "$OS" in
    linux) sudo dnf install -y git ;;
    macos) brew install git ;;
    esac
  fi
  # podman
  if ! command -v "podman" &>/dev/null; then
    case "$OS" in
    linux) sudo dnf install -y podman podman-compose && echo -e "${I_OK}podman installed!" || echo -e "${I_ERR}failed to install podman!" ;;
    macos) brew install podman podman-compose && echo -e "${I_OK}podman installed!" || echo -e "${I_ERR}failed to install podman!" ;;
    esac
  fi
  # gum
  if ! command -v "gum" &>/dev/null; then
    case "$OS" in
    linux) sudo dnf install -y "gum" && echo -e "${I_OK}gum installed!" || echo -e "${I_ERR}failed to install gum!" ;;
    macos) brew install "gum" && echo -e "${I_OK}gum installed!" || echo -e "${I_ERR}failed to install gum!" ;;
    esac
  fi
}

function install() {
  # Check if installation directory is a git repository
  if [[ -d "$ONESETUP_DIR" ]]; then
    if ! git -C "$ONESETUP_DIR" rev-parse --git-dir >/dev/null 2>&1; then
      sudo rm -rf "$ONESETUP_DIR" && echo -e "${I_INFO}There was a broken installation at $ONESETUP_DIR. Deletion complete."
    fi
  fi
  # Check if installation directory is up-to-date
  if [[ -d "$ONESETUP_DIR" ]]; then
    git -C "$ONESETUP_DIR" fetch
    local behind_count
    local ahead_count
    behind_count=$(git -C "$ONESETUP_DIR" rev-list --count HEAD..@{u})
    ahead_count=$(git -C "$ONESETUP_DIR" rev-list --count @{u}..HEAD)
    if (($behind_count > 0)) || (($ahead_count > 0)); then
      if (($behind_count > 0)) && (($ahead_count > 0)); then
        echo -e "${I_WARN}The installation directory is $behind_count commits behind and $ahead_count commits ahead of the remote (https://github.com/$ONESETUP_REPO)."
        echo -e "${I_ERR}Please Check! Exiting.." && exit 0
      elif (($ahead_count > 0)); then
        echo -e "${I_WARN}The installation directory is $ahead_count commits ahead of the remote (https://github.com/$ONESETUP_REPO)."
        echo -e "${I_ERR}Please Check! Exiting.." && exit 0
      elif (($behind_count > 0)); then
        echo -e "${I_INFO}The installation directory is $behind_count commits behind of the remote (https://github.com/$ONESETUP_REPO)."
        echo -e "${I_INFO}Updating.."
        sudo rm -rf "$ONESETUP_DIR" && sudo git clone "$onesetup_uri_https" "$ONESETUP_DIR"
      fi
    else
      echo -e "${I_WARN}The installation directory is up-to-date with the remote (https://github.com/$ONESETUP_REPO)."
      echo -e "${I_INFO}Skipping installation.."
    fi
  fi
  # Install only if directory is empty.
  if [[ ! -d "$ONESETUP_DIR" ]]; then
    echo -e "${I_INFO}Onesetup is not installed yet. Installing to ${ONESETUP_DIR} .." && sleep 1
    sudo git clone "$onesetup_uri_https" "$ONESETUP_DIR" && echo -e "${I_OK}Installation complete!"
  fi
  # Set permissions
  sudo chmod 774 "$ONESETUP_DIR" && echo -e "${I_OK}Permissions on installation directory set! (744): $ONESETUP_DIR" || echo -e "${I_ERR}Failed to set permissions on installation directory! (744): $ONESETUP_DIR"
  sudo chown -R "$USER:wheel" "$ONESETUP_DIR" && echo -e "${I_OK}Ownership on installation directory set! ($USER:wheel): $ONESETUP_DIR" || echo -e "${I_ERR}Failed to set ownership on installation directory! ($USER:wheel): $ONESETUP_DIR"

  # Check which Bin Directory to use
  local bin_dir
  if [[ -d "/usr/local/bin" ]]; then
    bin_dir="/usr/local/bin"
    echo -e "${I_OK}Bin Directory found at: [ ${FG_GREEN}/usr/local/bin${S_RESET} ]"
  elif [[ -d "/usr/bin" ]]; then
    bin_dir="/usr/bin"
    echo -e "${I_OK}Bin Directory found at: [ ${FG_GREEN}/usr/bin${S_RESET} ]"
  elif [[ -d "/bin" ]]; then
    echo -e "${I_WARN}No Bin Directory found at: [ ${FG_RED}/usr/local/bin${S_RESET} ] or [ ${FG_RED}/usr/bin${S_RESET} ]"
    echo -e "${I_INFO}Falling back to System Bin Directory: [ ${FG_GREEN}/bin${S_RESET} ]"
    bin_dir="/bin"
  else
    echo -e "${I_ERR}No bin directory found. Please ensure one of the following directories exists with ${S_BOLD}${FG_BLUE}rwx${S_RESET} permissions for the root user: [ ${FG_RED}/usr/local/bin${S_RESET} ] [ ${FG_RED}/usr/bin${S_RESET} ] [ ${FG_RED}/bin${S_RESET} ]"
    exit 1
  fi
  # Rollout executables to bin_dir
  for file in "${ONESETUP_DIR}"/bin/*; do
    if [[ -f "$file" ]]; then
      local filename
      filename=$(basename "$file")
      sudo cp -f "$file" "$bin_dir" && echo -e "${I_OK}${FG_GREEN}$filename${S_RESET} copied to ${FG_GREEN}$bin_dir${S_RESET}" || echo -e "${I_ERR}Failed to copy ${FG_RED}$filename${S_RESET} to ${FG_RED}$bin_dir${S_RESET}"
    fi
  done
}

# Call Main Function with args
main "$@"
