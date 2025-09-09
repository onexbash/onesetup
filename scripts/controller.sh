#!/usr/bin/env bash
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

# Debug
function debug() {
  echo -e "ONESETUP_DIR: $ONESETUP_DIR"
  echo -e "ONESETUP_REPO: $ONESETUP_REPO"
  echo -e "DOTFILES_DIR: $DOTFILES_DIR"
  echo -e "DOTFILES_REPO: $DOTFILES_REPO"
}

main && debug
