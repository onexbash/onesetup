#!/usr/bin/env bash
# Variables
REPO_URL="https://github.com/onexbash/onesetup.git"
INSTALL_DIR="/opt/onesetup"
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
# Load helper script
source "$SCRIPT_DIR/helper.sh"
load_stylings && set_modes

echo -e "${I_INFO}Onesetup will now prepare the Ansible control-node on this Machine (containerized)."
echo -e "${I_INFO}Please make sure your system is up-to-date before proceeding..." && sleep 5

# Detect OS
OS="$(uname -s)"
case "$OS" in
    Linux*)     PLATFORM="linux";;
    Darwin*)    PLATFORM="macos";;
    *)          echo -e "Unsupported OS: $OS"; exit 1;;
esac
echo -e "${I_OK}Detected platform: $PLATFORM"

# Install prerequisites
install_prerequisites() {
  # git
    if ! command -v git &> /dev/null; then
        case "$PLATFORM" in
            linux) sudo dnf install -y git || sudo apt install -y git;;
            macos) brew install git;;
        esac
    fi
  # podman
    if ! command -v podman &> /dev/null; then
        case "$PLATFORM" in
            linux)
                sudo dnf install -y podman podman-compose || sudo apt install -y podman podman-compose
                ;;
            macos)
                brew install podman podman-compose
                ;;
        esac
    fi
}


# Install prerequisites
echo -e "${I_OK}Checking prerequisites..."
install_prerequisites

# Cleanup installation directory
echo -e "${I_OK}Preparing installation directory..."
if [[ -d "$INSTALL_DIR" ]]; then
    sudo rm -rf "$INSTALL_DIR"
fi
sudo mkdir -p "$(dirname "$INSTALL_DIR")"

# Clone repository
echo -e "${I_OK}Cloning repository..."
sudo git clone "$REPO_URL" "$INSTALL_DIR" || {
    echo -e "${I_ERR}Failed to clone repository"
    exit 1
}

# Set permissions
echo -e "${I_OK}Setting permissions..."
sudo chmod 774 "$INSTALL_DIR"
if [[ "$PLATFORM" == "linux" ]]; then
    sudo chown -R "$(id -u):$(id -g)" "$INSTALL_DIR"
else
    sudo chown -R "$(id -u)" "$INSTALL_DIR"
fi

# Prepare Container Engine (Podman Machine)
if ! podman machine list | grep -q running; then
    podman machine init "onesetup" --disk-size "32"
    podman machine start "onesetup"
fi

# Start container
echo -e "${I_OK}Starting container..."
cd "$INSTALL_DIR" || {
    echo -e "${I_ERR}Failed to enter installation directory: $INSTALL_DIR"
    exit 1
}

podman-compose -f "$INSTALL_DIR/docker-compose.yml" up && echo -e "${I_OK}Control-Node installed and started successfully!"
