#!/usr/bin/env bash

# call helper functions
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "$SCRIPT_DIR/helper.sh"
load_stylings && set_modes && load_tools


# Encrypt String with Ansible-Vault
function encrypt_string() {
  printf "%b" "${I_ASK}Secret to Encrypt: "
  read -r secret
  printf "%b" "${I_ASK}Variable Name: "
  read -r varname
  ansible-vault encrypt_string \
    --show-input \
    --vault-id "xsetup@prompt" \
    --encrypt-vault-id "xsetup" \
    --name "$varname" \
    "$secret" | pbcopy
  echo -e "${I_OK}Encrypted string copied to clipboard."
}
# Encrypt File Content with Ansible-Vault
function encrypt_file() {
  local filepath="$1"

  # Check if file exists
  if [[ ! -f "$filepath" ]]; then
    echo -e "${I_ERR}File not found: $filepath"
    return 1
  fi

  # Read the file content into a variable
  local filecontent
  filecontent=$(<"$filepath")

  # Ask for variable name
  printf "%b" "${I_ASK}Variable Name: "
  read -r varname

  # Encrypt and copy to clipboard
  ansible-vault encrypt_string \
    --show-input \
    --vault-id "xsetup@prompt" \
    --encrypt-vault-id "xsetup" \
    --name "$varname" \
    "$filecontent" | pbcopy

  echo -e "${I_OK}Encrypted file content copied to clipboard."
}
# User Selection to decide which encrypt function to run
choice=$(gum choose "Encrypt String" "Encrypt File Content" \
  --cursor.foreground "#cba6f7" \
  --header.foreground "#cba6f7" \
  --selected.foreground "#cba6f7" \
  --header "Choose:" \
  --no-show-help \
  --ordered
)
case "$choice" in
  "Encrypt String")
    encrypt_string
    ;;
  "Encrypt File Content")
    # gum file picker
    filepath=$(gum file \
      --cursor.foreground "#cba6f7" \
      --header.foreground "#cba6f7" \
      --selected.foreground "#cba6f7" \
      --all
      )  
    encrypt_file "$filepath"
    ;;
esac
