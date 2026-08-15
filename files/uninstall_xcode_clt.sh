#!/usr/bin/env bash

# -- XCode CommandLineTools: Automatic Removal Script -- #
# NOTE: called by ansible playbook (./pre_tasks/xcode.yml)

# Main Function
function main(){
  uninstall || echo -e "${I_WARN}Failed to uninstall XCode CommandLineTools"
}

# Uninstall XCode CommandLineTools
function uninstall(){
  # Remove Installation Directory
  sudo rm -rf /Library/Developer/CommandLineTools
  # Reset pointer to Installation Directory
  sudo xcode-select --reset
  # Remove User Installation
  rm -rf "~/Library/Developer/CommandLineTools"
  # Verify Removal
  echo -e "${I_OK}XCode CommandLineTools uninstalled successfully!"
  xcode-select -p 2>&1 || echo -e "${I_OK}xcode-select: no developer dir (expected)"
}

# Call Main Function with args
main "$@"
