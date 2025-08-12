#!/usr/bin/env bash
# -- -- -- -- -- -- -- -- -- -- #
# --   ONESETUP EXECUTABLE   -- #
# -- -- -- -- -- -- -- -- -- -- #

# call helper functions
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "$SCRIPT_DIR/helper.sh"
load_stylings && set_modes

# get project root
current_dir="$SCRIPT_DIR"
while [[ "$current_dir" != "/" ]]; do
  if [[ -f "$current_dir/main.yml" || -f "$current_dir/ansible.cfg" ]]; then
    break # exit loop
  fi
  current_dir=$(dirname "$current_dir")
done
ONESETUP_ROOT="$current_dir"

# run playbook
run(){
  ansible-playbook --ask-vault-pass "$ONESETUP_ROOT/main.yml"
}
run
