#!/usr/bin/env bash
# Variables
ONESETUP_DIR="/opt/onesetup"
ONESETUP_REPO_HTTPS="https://github.com/onexbash/onesetup.git"
DOTFILES_DIR="/opt/dotfiles"
DOTFILES_REPO_HTTPS="https://github.com/onexbash/dotfiles.git"
THIS_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

# Load helper script
source "$THIS_DIR/scripts/helper.sh"
load_stylings && set_modes

# Info Prompt 
echo -e "${I_INFO}Onesetup will now prepare the Ansible control-node on this Machine (containerized)." && echo -e "${I_INFO}Please make sure your system is up-to-date before proceeding..." && sleep 5

# Detect OS
OS="$(uname -s)"
case "$OS" in
  Linux*)     PLATFORM="linux";;
  Darwin*)    PLATFORM="macos";;
  *)          echo -e "Unsupported OS: $OS"; exit 1;;
esac
echo -e "${I_OK}Detected platform: $PLATFORM"

# Ensure prerequisites are satisfied
function prerequisites() {
  # homebrew
  if [[ "$PLATFORM" = "macos" ]]; then
    if ! command -v "brew" &> /dev/null; then
      echo -e "${I_ERR}Homebrew not available. Please install from 'https://brew.sh' & re-run script"
    fi
  fi
  # git
  if ! command -v "git" &> /dev/null; then
    case "$PLATFORM" in
      linux) sudo dnf install -y git;;
      macos) brew install git;;
    esac
  fi
  # podman
  if ! command -v "podman" &> /dev/null; then
    case "$PLATFORM" in
      linux)
        sudo dnf install -y podman podman-compose
        ;;
      macos)
        brew install podman podman-compose
        ;;
    esac
  fi
}

function install() {
  # Cleanup installation directory
  echo -e "${I_OK}Preparing installation directory..."
  if [[ -d "$ONESETUP_DIR" ]]; then
    sudo rm -rf "$ONESETUP_DIR"
  fi
  sudo mkdir -p "$(dirname "$ONESETUP_DIR")"
  
  # Clone repository
  echo -e "${I_OK}Cloning repository..."
  sudo git clone "$ONESETUP_REPO_HTTPS" "$ONESETUP_DIR" || {
    echo -e "${I_ERR}Failed to clone repository" && exit 1
  }
  
  # Set permissions
  echo -e "${I_OK}Setting permissions..."
  sudo chmod 774 "$ONESETUP_DIR"
  if [[ "$PLATFORM" == "linux" ]]; then
    sudo chown -R "$(id -u):$(id -g)" "$ONESETUP_DIR"
  else
    sudo chown -R "$(id -u)" "$ONESETUP_DIR"
  fi
}

function connection() {
  echo "connecting.."
  # ssh-keygen -t ed25519 -C "onesetup@control-node"
}

function run() {
  # Build & Run Control Node Container
  podman-compose -f "$ONESETUP_DIR/docker-compose.yml" build "onesetup" --no-cache && echo -e "${I_OK}Control-Node image built successfully!"
  podman-compose -f "$ONESETUP_DIR/docker-compose.yml" run "onesetup" && echo -e "${I_OK}Control-Node container successfully running!"
}

echo -e "${I_OK}Checking prerequisites..." && prerequisites
echo -e "${I_OK}Installing Control-Node..." && install
echo -e "${I_OK}Establishing Connection..." && connection
echo -e "${I_OK}Running Control-Node Container..." && run
