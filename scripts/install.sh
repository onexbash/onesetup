#!/usr/bin/env bash

# Environment Variables
export ONESETUP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/onesetup"
export ONESETUP_REPO="onexbash/onesetup"
export DOTFILES_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles"
export DOTFILES_REPO="onexbash/dotfiles"

# Variables
ONESETUP_REPO_HTTPS="https://github.com/${ONESETUP_REPO}.git"
ONESETUP_REPO_RAW="https://raw.githubusercontent.com/${ONESETUP_REPO}/main"
DOTFILES_REPO_RAW="https://raw.githubusercontent.com/${DOTFILES_REPO}/main"
DOTFILES_REPO_HTTPS="https://github.com/${DOTFILES_REPO}.git"

# Load Scripts
function load_scripts() {
  # Load helper script
  source <(curl -s "$ONESETUP_REPO_RAW/scripts/helper.sh") && echo -e "${I_OK}Helper Script loaded!" || echo -e "${I_ERR}Please make sure you are connected to the internet and try again."
  # Load .env.public
  set -a
  source <(curl -s "$ONESETUP_REPO_RAW/.env.public") && echo -e "${I_OK}Environment Variables Loaded from .env.public!" || echo -e "${I_ERR}Please make sure you are connected to the internet and try again."
  set +a
}

# Detect Operating System
function detect_os() {
  OS="$(uname -s)"
  case "$OS" in
  Linux*) PLATFORM="linux" ;;
  Darwin*) PLATFORM="macos" ;;
  Windows*) PLATFORM="windows" ;;
  *) PLATFORM="unknown" ;;
  esac
  case "$PLATFORM" in
  linux) echo -e "${I_OK}Supported platform detected: $PLATFORM" ;;
  macos) echo -e "${I_OK}Supported platform detected: $PLATFORM" ;;
  windows) echo -e "${I_ERR}haha, windows is not supported you fcking looser" && exit 1 ;;
  *) echo -e "Whatever this sh*t you're running this on is, it's not supported!: $OS" && exit 1 ;;
  esac
}

# Ensure prerequisites are satisfied
function prerequisites() {
  # homebrew
  if [[ "$PLATFORM" = "macos" ]]; then
    if ! command -v "brew" &>/dev/null; then
      echo -e "${I_ERR}Homebrew not available. Please install from 'https://brew.sh' & re-run script"
    fi
  fi
  # git
  if ! command -v "git" &>/dev/null; then
    case "$PLATFORM" in
    linux) sudo dnf install -y git ;;
    macos) brew install git ;;
    esac
  fi
  # podman
  if ! command -v "podman" &>/dev/null; then
    case "$PLATFORM" in
    linux) sudo dnf install -y podman podman-compose && echo -e "${I_OK}podman installed!" || echo -e "${I_ERR}failed to install podman!" ;;
    macos) brew install podman podman-compose && echo -e "${I_OK}podman installed!" || echo -e "${I_ERR}failed to install podman!" ;;
    esac
  fi
  # gum
  if ! command -v "gum" &>/dev/null; then
    case "$PLATFORM" in
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
    local behind_count=$(git -C "$ONESETUP_DIR" rev-list --count HEAD..@{u})
    local ahead_count=$(git -C "$ONESETUP_DIR" rev-list --count @{u}..HEAD)
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
        sudo rm -rf "$ONESETUP_DIR" && sudo git clone "$ONESETUP_REPO_HTTPS" "$ONESETUP_DIR"
      fi
    else
      echo -e "${I_WARN}The installation directory is up-to-date with the remote (https://github.com/$ONESETUP_REPO)."
      echo -e "${I_INFO}Skipping installation.."
    fi
  fi
  # Install only if directory is empty.
  if [[ ! -d "$ONESETUP_DIR" ]]; then
    echo -e "${I_INFO}Onesetup is not installed yet. Installing to ${ONESETUP_DIR} .." && sleep 1
    sudo git clone "$ONESETUP_REPO_HTTPS" "$ONESETUP_DIR" && echo -e "${I_OK}Installation complete!"
  fi
  # Set permissions
  sudo chmod 774 "$ONESETUP_DIR" && echo -e "${I_OK}Permissions on installation directory set! (744): $ONESETUP_DIR" || echo -e "${I_ERR}Failed to set permissions on installation directory! (744): $ONESETUP_DIR"
  sudo chown -R "$USER:wheel" "$ONESETUP_DIR" && echo -e "${I_OK}Ownership on installation directory set! ($USER:wheel): $ONESETUP_DIR" || echo -e "${I_ERR}Failed to set ownership on installation directory! ($USER:wheel): $ONESETUP_DIR"

  # Check which Bin Directory to use
  local bin_dir
  if [[ -d "/usr/local/bin" ]]; then
    bin_dir="/usr/local/bin"
    echo -e "${I_OK}User Bin Directory found at: [ ${FG_GREEN}/usr/local/bin${S_RESET} ]"
  elif [[ -d "/usr/bin" ]]; then
    bin_dir="/usr/bin"
    echo -e "${I_OK}User Bin Directory found at: [ ${FG_GREEN}/usr/bin${S_RESET} ]"
  elif [[ -d "/bin" ]]; then
    echo -e "${I_WARN}No User Bin Directory found at: [ ${FG_RED}/usr/local/bin${S_RESET} ] or [ ${FG_RED}/usr/bin${S_RESET} ]"
    echo -e "${I_INFO}Falling back to System Bin Directory: [ ${FG_GREEN}/bin${S_RESET} ]"
    bin_dir="/bin"
  else
    echo -e "${I_ERR}No bin directory found. Please ensure one of the following directories exists with ${S_BOLD}${FG_BLUE}rwx${S_RESET} permissions for the root user: [ ${FG_RED}/usr/local/bin${S_RESET} ] [ ${FG_RED}/usr/bin${S_RESET} ] [ ${FG_RED}/bin${S_RESET} ]"
    exit 1
  fi
  # Rollout executables to bin_dir
  for file in ${ONESETUP_DIR}/bin/*; do
    if [[ -f "$file" ]]; then
      local filename=$(basename "$file")
      sudo cp "$file" "$bin_dir" && echo -e "${I_OK}${FG_GREEN}$filename${S_RESET} copied to ${FG_GREEN}$bin_dir${S_RESET}" || echo -e "${I_ERR}Failed to copy ${FG_RED}$filename${S_RESET} to ${FG_RED}$bin_dir${S_RESET}"
    fi
  done
}

# Function Calls
load_scripts
prerequisites && echo -e "${I_OK}Prerequesites checked!"
install && echo -e "${I_OK}Onesetup installed!"
