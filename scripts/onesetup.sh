#!/usr/bin/env bash
# Build & Run Control-Node Container
function run() {
  # build

  podman-compose -f "$ONESETUP_DIR/docker-compose.yml" build \
    --build-arg "ONESETUP_DIR=$ONESETUP_DIR" \
    --build-arg "DOTFILES_DIR=$DOTFILES_DIR" \
    --build-arg "ONESETUP_REPO=$ONESETUP_REPO" \
    --build-arg "DOTFILES_REPO=$DOTFILES_REPO" \
    "onesetup" \
    && echo -e "${I_OK}Control-Node image built successfully!" \
    || echo -e "${I_ERR}Control-Node Container Image failed to build!"
  # run
  podman-compose -f "$ONESETUP_DIR/docker-compose.yml" run "onesetup" \
    && echo -e "${I_OK}Control-Node container successfully running!" \
    || echo -e "${I_ERR}Control-Node Container failed to run!"
}

