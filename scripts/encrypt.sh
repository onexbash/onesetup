#!/usr/bin/env bash

# -- ANSIBLE VAULT ENCRYPT SCRIPT -- #
# Use this script to encrypt your plaintext secrets.yml to an encrypted ansible-vault file (secrets.yml.vault)
# ! NEVER commit plaintext password files to version control. Publish the encrypted file instead.
# -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- #

# call helper functions
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "$SCRIPT_DIR/helper.sh"
load_stylings
set_modes

# get project root
current_dir="$SCRIPT_DIR"
while [[ "$current_dir" != "/" ]]; do
  if [[ -f "$current_dir/main.yml" || -f "$current_dir/ansible.cfg" ]]; then
    break # exit loop
  fi
  current_dir=$(dirname "$current_dir")
done
ONESETUP_ROOT="$current_dir"

SECRET_FILE_PLAINTEXT=$ONESETUP_ROOT/secrets.yml
SECRET_FILE_ENCRYPTED=$ONESETUP_ROOT/secrets.yml.vault

# check if encrypted secret file exists. If yes, prompt if it should be overwritten.
if [[ -f "$SECRET_FILE_ENCRYPTED" ]]; then
  encrypted_file_present=1
  echo -e "${I_WARN}An ansible-vault encrypted secret file already exists: $SECRET_FILE_ENCRYPTED"
  read -p "$(echo -e "${I_ASK_YN}Overwrite? ")" -r answer
  case "$answer" in
    [Yy]) answer_overwrite=1 ;;
    *) answer_overwrite=0 ;;
  esac
else
  encrypted_file_present=0
fi

# check if plaintext secret file exists
if [[ ! -f "$SECRET_FILE_PLAINTEXT" ]]; then
  echo -e "${I_ERR}No plaintext secret file found in $SECRET_FILE_PLAINTEXT. Please make sure it exists before running this script again."
  exit 1 # exit with error
fi

# declare encrypt function
function encrypt(){
  ansible-vault encrypt "$SECRET_FILE_PLAINTEXT" --output "$SECRET_FILE_ENCRYPTED"
  echo -e "${I_DONE}Secrets encrypted to: $SECRET_FILE_ENCRYPTED"
  echo -e "${I_INFO}You can now use this as vars file in ansible."
}

# call encrypt function
if [[ "$encrypted_file_present" -eq 0 ]]; then
  encrypt
elif [[ "$encrypted_file_present" -eq 1 ]]; then
  if [[ "$answer_overwrite" -eq 1 ]]; then
    encrypt
  elif [[ "$answer_overwrite" -eq 0 ]]; then
    echo -e "${I_ERR}Encrypted Secret File already exists & user doesn't want to overwrite it. \n Exiting.."
    exit 1
  fi
fi
