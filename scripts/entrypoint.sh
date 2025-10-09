#!/usr/bin/env bash
# --                             -- #
# -- CONTAINER ENTRYPOINT SCRIPT -- #
# --                             -- #

function main() {
  # Install Modules from Ansible Galaxy
  if [ -f "requirements.yml" ]; then
    ansible-galaxy role install -r "requirements.yml"
  else
    echo "WARN: requirements.yml not found. Nothing will be installed from Ansible Galaxy."
  fi
  # Run the Ansible playbook once initially
  if [ -f "main.yml" ]; then
    ansible-playbook --ask-vault-password "main.yml"
  else
    echo "ERROR: main.yml not found. Skipping initial playbook run."
  fi
  exec /bin/bash
}

# Call Main Function with args
main "$@"
