#!/bin/bash

# Run the Ansible playbook once initially
if [ -f "main.yml" ]; then
  echo "Running the complete ansible-playbook..."
  /usr/bin/ansible-playbook --ask-vault-password "main.yml"
else
  echo "Warning: main.yml not found. Skipping initial playbook run."
fi

# Drop into an interactive shell for more commands
echo "Initial playbook execution completed. Starting interactive shell..."
exec /bin/bash
