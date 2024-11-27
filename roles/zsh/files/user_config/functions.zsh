#!/usr/bin/env zsh

# use fzf to display a selection of nvim directories inside ~/.config
function nv-select() {
  local config=$(fd --max-depth 1 --glob 'nvim*' ~/.config | fzf --prompt="Neovim Configs > " --height=~50% --layout=reverse --border --exit-0)
  [[ -z $config ]] && echo "No config selected" && return
  NVIM_APPNAME=$(basename $config) nvim $@
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
    echo -e "\e[31mPlease provide a directory path!\e[0m"
    return 1
  fi

  # Check if the provided path is a directory
  if [ ! -d "$1" ]; then
    echo -e "\e[31mError: The provided path is not a valid directory.\e[0m"
    return 1
  fi

  # Calculate the directory size
  dir_size=$(du -sh "$1" 2>/dev/null | awk '{print $1}')

  # Display the size in a nicely formatted way
  echo -e "\e[34m=============================\e[0m"
  echo -e "\e[32m| Directory Size: \e[33m$dir_size \e[32m|\e[0m"
  echo -e "\e[32m| Directory Path: \e[33m$1 \e[32m|\e[0m"
  echo -e "\e[34m=============================\e[0m"
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
    echo -e "${I_OK}Screenshot saved to ~/nas/gallery/screenshots/$filename"
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
  mdls -name kMDItemCFBundleIdentifier
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
