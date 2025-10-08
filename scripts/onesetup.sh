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

function setup_container() {
  # check if a podman machine with name "onesetup" exists
  if podman machine list --format "{{.Name}}" | grep -q "^onesetup$"; then
    echo -e "${I_OK}Podman Machine [onesetup] exists!"
  else
    podman machine init "onesetup" \
      --cpus 4 \
      --memory 4096 \
      --disk-size 10 \
      --rootful=false \
      --now &&
      echo -e "${I_OK}Podman Machine [onesetup] has been created & started!"
  fi
  # check if the machine is running
  if podman machine inspect "onesetup" 2>/dev/null | jq -e '.[0].State == "running"' >/dev/null; then
    echo -e "${I_OK}Podman Machine [onesetup] is running!"
  else
    podman machine start "onesetup"
  fi
}

# Build & Run Control-Node Container
function run() {
  # specify container engine to use
  export CONTAINER_CONNECTION="onesetup"
  # build
  podman-compose \
    -f "$ONESETUP_DIR/docker-compose.yml" build \
    --build-arg "ONESETUP_DIR=$ONESETUP_DIR" \
    --build-arg "DOTFILES_DIR=$DOTFILES_DIR" \
    --build-arg "ONESETUP_REPO=$ONESETUP_REPO" \
    --build-arg "DOTFILES_REPO=$DOTFILES_REPO" \
    "onesetup" &&
    echo -e "${I_OK}Control-Node image built successfully!" ||
    echo -e "${I_ERR}Control-Node Container Image failed to build!"
  # run
  podman-compose \
    -f "$ONESETUP_DIR/docker-compose.yml" run \
    "onesetup" &&
    echo -e "${I_OK}Control-Node container successfully running!" ||
    echo -e "${I_ERR}Control-Node Container failed to run!"
}

load_scripts && setup_container && run
