#!/usr/bin/env bash
# Environment Variables
GITHUB_USERNAME="onexbash"
ONESETUP_DIR="${HOME}/onesetup"
DOTFILES_DIR="/opt/dotfiles"
DOTFILES_REPO_NAME="dotfiles" && ONESETUP_REPO_NAME="onesetup"
ONESETUP_REPO_HTTPS="https://github.com/$GITHUB_USERNAME/$ONESETUP_REPO_NAME.git"
DOTFILES_REPO_HTTPS="https://github.com/$GITHUB_USERNAME/$DOTFILES_REPO_NAME.git"
ONESETUP_REPO_RAW="https://raw.githubusercontent.com/$GITHUB_USERNAME/$ONESETUP_REPO_NAME/main"
DOTFILES_REPO_RAW="https://raw.githubusercontent.com/$GITHUB_USERNAME/$DOTFILES_REPO_NAME/main"


# Load helper script
function load_helper(){
  source <(curl -s "$ONESETUP_REPO_RAW/scripts/helper.sh") || echo -e "${I_ERR}Please make sure you are connected to the internet and try again."
  load_stylings && set_modes
}

# Detect Operating System
function detect_os() {
  OS="$(uname -s)"
  case "$OS" in
    Linux*) PLATFORM="linux";;
    Darwin*) PLATFORM="macos";;
    Windows*) PLATFORM="windows";;
    *) PLATFORM="unknown";;
  esac
  case "$PLATFORM" in
    linux) echo -e "${I_OK}Supported platform detected: $PLATFORM";;
    macos) echo -e "${I_OK}Supported platform detected: $PLATFORM";;
    windows) echo -e "${I_ERR}haha, windows is not supported you fcking looser" && exit 1;;
    *) echo -e "Whatever this sh*t you're running this on is, it's not supported!: $OS" && exit 1;;
  esac
}

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
      linux) sudo dnf install -y podman podman-compose && echo -e "${I_OK}podman installed!" || echo -e "${I_ERR}failed to install podman!";;
      macos) brew install podman podman-compose && echo -e "${I_OK}podman installed!" || echo -e "${I_ERR}failed to install podman!";;
    esac
  fi 
}

function install() { 
  # Check if installation directory is a git repository
  if [[ -d "$ONESETUP_DIR" ]]; then
    if ! git -C "$ONESETUP_DIR" rev-parse --git-dir > /dev/null 2>&1; then
      sudo rm -rf "$ONESETUP_DIR" && echo -e "${I_INFO}There was a broken installation at $ONESETUP_DIR. Deletion complete."
    fi
  fi
  # Check if installation directory is up-to-date
  if [[ -d "$ONESETUP_DIR" ]]; then
    git -C "$ONESETUP_DIR" fetch
    local behind_count=$(git -C "$ONESETUP_DIR" rev-list --count HEAD..@{u})
    local ahead_count=$(git -C "$ONESETUP_DIR" rev-list --count @{u}..HEAD)
    if (( $behind_count > 0 )) || (( $ahead_count > 0 )); then
      if (( $behind_count > 0 )) && (( $ahead_count > 0 )); then
        echo -e "${I_WARN}The installation directory is $behind_count commits behind and $ahead_count commits ahead of the remote (https://github.com/$GITHUB_USERNAME/$ONESETUP_REPO_NAME)."
        echo -e "${I_ERR}Please Check! Exiting.." && exit 0
      elif (( $ahead_count > 0 )); then
        echo -e "${I_WARN}The installation directory is $ahead_count commits ahead of the remote (https://github.com/$GITHUB_USERNAME/$ONESETUP_REPO_NAME)."
        echo -e "${I_ERR}Please Check! Exiting.." && exit 0
      elif (( $behind_count > 0 )); then
        echo -e "${I_INFO}The installation directory is $behind_count commits behind of the remote (https://github.com/$GITHUB_USERNAME/$ONESETUP_REPO_NAME)."
        echo -e "${I_INFO}Updating.."
        sudo rm -rf "$ONESETUP_DIR" && sudo git clone "$ONESETUP_REPO_HTTPS" "$ONESETUP_DIR"
      fi
    else
      echo -e "${I_WARN}The installation directory is up-to-date with the remote (https://github.com/$GITHUB_USERNAME/$ONESETUP_REPO_NAME)."
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
}
# Build & Run Control-Node Container
function run() {
  podman-compose -f "$ONESETUP_DIR/docker-compose.yml" build \
    --build-arg "ONESETUP_DIR=$ONESETUP_DIR" \
    --build-arg "ONESETUP_REPO_NAME=$ONESETUP_REPO_NAME" \
    "onesetup" \
    && echo -e "${I_OK}Control-Node image built successfully!"
  podman-compose -f "$ONESETUP_DIR/docker-compose.yml" run "onesetup" && echo -e "${I_OK}Control-Node container successfully running!"
}

# Function Calls
load_helper && echo -e "${I_OK}Helper Script loaded!"
prerequisites && echo -e "${I_OK}Prerequesites checked!"
install && echo -e "${I_OK}Onesetup installed!"
run && echo -e "${I_OK}Control-Node running!"
