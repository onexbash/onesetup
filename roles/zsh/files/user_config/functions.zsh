#!/usr/bin/env zsh

# use fzf to display a selection of nvim directories inside $XDG_CONFIG_HOME
function nv-select() {
  local config=$(fd --max-depth 1 --glob 'nvim*' ${XDG_CONFIG_HOME:-$HOME/.config} | fzf --prompt="Neovim Configs > " --height=~50% --layout=reverse --border --exit-0)
  [[ -z $config ]] && echo "No config selected" && return
  NVIM_APPNAME=$(basename $config) nvim $@
}


function set_node() {
  local last_supported_version="18"
  
  if ! command -v "fnm" >>/dev/null 2>&1; then
    echo -e "${I_ERR} fnm not available"
    return 1 # exit with error code
  else
    echo -e "${I_OK} fnm available"
  fi

  # Get all versions, filter by major versions newer than last_supported_version
  local versions=$(fnm list-remote | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$')
  
  # Dynamically fetch the latest version for each major version > last_supported_version
  local major_versions=($(echo "$versions" | awk -F. '{print substr($1,2)}' | sort -n | uniq))
  
  for major in "${major_versions[@]}"; do
    if (( major > last_supported_version )); then
      # Get the latest version for this major version
      local latest_major=$(echo "$versions" | grep -E "^v${major}\.[0-9]+\.[0-9]+$" | sort -V | tail -n1)
      if ! fnm ls | grep -q "$latest_major"; then
        echo -e "${I_INFO} Installing Node.js $latest_major"
        fnm install "$latest_major"
      else
        echo -e "${I_INFO} Node.js $latest_major already installed"
      fi
    fi
  done

  # Ensure the absolute latest version is installed
  local latest=$(echo "$versions" | tail -n1)
  if ! fnm ls | grep -q "$latest"; then
    echo -e "${I_INFO} Installing the absolute latest Node.js version $latest"
    fnm install "$latest"
  else
    echo -e "${I_INFO} Latest version $latest already installed"
  fi
}

function qr2otp() {

# Temporary file for the screenshot
TEMP_FILE=$(mktemp).png

# Capture a portion of the screen
echo "Select the QR code on your screen..."
screencapture -i "$TEMP_FILE"

# Scan the QR code for TOTP secret
zbarimg "$TEMP_FILE" | grep "QR-Code:" | sed 's/^QR-Code://'

# Clean up
rm "$TEMP_FILE"

}

function show() {
    # check if --sym is passed
    if [[ $* == *--sym* ]]; then
      echo -e "symlink"
    else
      echo -e "no symlink"
    fi
}

function filesize() {
  # Check if the user provided a directory path
  if [ -z "$1" ]; then
    echo -e "${I_ERR}Please provide a directory path!${C_RESET}"
    return 1
  fi

  # Check if the provided path is a directory
  if [ ! -d "$1" ]; then
    echo -e "${I_ERR} The provided path is not a valid directory.${C_RESET}"
    return 1
  fi

  # Calculate the directory size
  dir_size=$(du -sh "$1" 2>/dev/null | awk '{print $1}')

  # Display the size in a nicely formatted way
  echo -e "${C_BLUE}=============================${C_RESET}"
  echo -e "${C_GREEN}| Directory Size: ${C_YELLOW}$dir_size ${C_GREEN}|${C_RESET}"
  echo -e "${C_GREEN}| Directory Path: ${C_YELLOW}$1 ${C_GREEN}|${C_RESET}"
  echo -e "${C_BLUE}=============================${C_RESET}"
}

# screenshot from cli
function ss() {
    # Define the screenshots directory
    SCREENSHOTS_DIR="$HOME/nas/gallery/screenshots" 
    # Define filename
    timestamp=$(date +"%Y_%m-%R") # get timestamp (YY/MM-hh/mm)
    filename="osx_screencapture_${timestamp}.png"
    # Take screenshot
    screencapture "${SCREENSHOTS_DIR}/$filename"
    echo -e "${I_OK}Screenshot saved to ${SCREENSHOTS_DIR}/$filename"
}
# wrapper function for yazi
function yz() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

# -- EXIFTOOL -- #
function exif() {
  if command -v exiftool >/dev/null 2>&1; then
    exiftool "-FileType" "-FileTypeExtension" "-FileSize" "-ImageSize" "-ImageWidth" "-ImageHeight" "-BitDepth" "-ColorType" "$@"
  else
    echo -e "${I_ERR} $(which exiftool) check if installed & available in '\$PATH'"
  fi
}


# get file permission info
function chinfo() {
  echo -e "${C_GREEN}$1${C_RESET}"
  echo -e "permissions: $(stat -c '%a' "$1")\nownership: $(stat -c '%U:%G' "$1")"
}

function ppath() {
  echo -e "${G_BORDER}${C_CYAN}            INCLUDED IN PATH${G_BORDER}"
  IFS=':' read -r -d '' path_array <<< "$PATH:"
  echo -e "${I_INFO} %s \n" "${(ps/:/)path_array}"
}
# -- NETWORK -- #
function ip-addr() {
  ifconfig en0 | grep inet | grep -v inet6 | cut -d ' ' -f2
}

function bundleid() {
  # Check if an argument is provided
  if [ -z "$1" ]; then
    echo -e "${I_ERR} Please provide an application path (e.g., /Applications/App.app)${C_RESET}"
    return 1
  fi

  # Check if the path exists
  if [ ! -e "$1" ]; then
    echo -e "${I_ERR} Application path does not exist: $1${C_RESET}"
    return 1
  fi

  # Get the bundle identifier
  local bundle_id=$(mdls -name kMDItemCFBundleIdentifier -raw "$1")

  # Check if bundle identifier was found
  if [ -z "$bundle_id" ] || [ "$bundle_id" = "(null)" ]; then
    echo -e "${I_ERR} Could not find bundle identifier for: $1${C_RESET}"
    return 1
  fi

  echo -e "${C_GREEN}Bundle Identifier for ${C_YELLOW}$1${C_GREEN}: ${C_BLUE}$bundle_id${C_RESET}"
}

# update homebrew
function brewup(){
  # Update homebrew
  echo -e "${C_TEXT}Updating Homebrew...\n"
  brew update
  # Update formulaes and casks
  echo -e "${C_TEXT}Upgrading homebrew formulaes and casks...\n"
  # Cleanup cache of unfinished downloads
  echo -e "${C_TEXT}Cleaning up homebrew cache...\n"
  brew cleanup
  # Show problems if any
  echo -e "${C_TEXT}Checking for homebrew issues...\n"
  brew doctor
}

# update python, pip, poetry
function pyup(){
  # update global pip packages
  pip install --upgrade $(pip list --user | awk '{echo $1}')
}

# run all update functions
function up(){
  brewup
  pyup
}
