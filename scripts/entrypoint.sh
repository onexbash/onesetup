#!/usr/bin/env bash
# --                             -- #
# -- CONTAINER ENTRYPOINT SCRIPT -- #
# --                             -- #

function main() {
  local container_mount="/home/onesetup/src"

  # Install Modules from Ansible Galaxy
  if [ -f "$container_mount/requirements.yml" ]; then
    ansible-galaxy role install -r "$container_mount/requirements.yml"
  else
    echo "WARN: $container_mount/requirements.yml not found. Nothing will be installed from Ansible Galaxy."
  fi
  # Run the Ansible playbook once initially
  if [ -f "$container_mount/main.yml" ]; then
    ansible-playbook --ask-vault-password "$container_mount/main.yml"
  else
    echo "ERROR: Main Playbook File not found at $container_mount/main.yml. Playbook was NOT applied!"
  fi
  exec /bin/bash
}

# Call Main Function with args
main "$@"
