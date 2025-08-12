#!/usr/bin/env bash
# -- -- -- -- -- -- -- -- -- -- -- -- -- #
# --   PREPARE REMOTE TARGET SCRIPT   -- #
# -- -- -- -- -- -- -- -- -- -- -- -- -- #

# Variables
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
# Load helper script
source "$SCRIPT_DIR/helper.sh"
load_stylings && set_modes && get_script_pwd 
# load_env_file "$PARENT_DIR" # TODO: uncomment as soon as .env files are used
echo -e "${I_DO}ONESETUP will now prepare your Remote Target."
print_sysinfo

# Ensure MacOS Built-In SSH is used
ensure_builtin_ssh() {
  local ssh_path sshd_path
  ssh_path=$(which ssh)
  sshd_path=$(which sshd)
  
  if [[ "$ssh_path" == "/usr/bin/ssh" ]] && [[ "$sshd_path" == "/usr/sbin/sshd" ]]; then
    echo -e "${I_OK}Using macOS built-in SSH client and server"
  elif [[ $ssh_path == *"brew"* ]] || [[ "$sshd_path" == *"brew"* ]]; then
    echo -e "${I_ERR}The OpenSSH Homebrew Formulae is used which isn't supported & conflicts with the built-in SSH version."
    echo -e "${I_DO}Removing.."
    brew rm --zap "openssh"
  else
    echo -e "${I_ERR}An unknown third-party SSH client/server is used which isn't supported by onesetup."
    echo -e "${I_INFO}SSH path: $ssh_path (expected: /usr/bin/ssh)"
    echo -e "${I_INFO}SSHD path: $sshd_path (expected: /usr/sbin/sshd)"
    echo -e "${I_INFO}Please remove it, ensure built-in SSH is used & restart this script"
    exit 1
  fi
}

# Ensure Remote-Login via SSH is enabled
ensure_remote_login() {
  if sudo systemsetup -getremotelogin 2>/dev/null | grep -q "On"; then
    echo -e "${I_OK}Remote Login via SSH enabled."
  else
    echo -e "${I_WARN}Remote Login via SSH disabled."
    echo -e "${I_DO}Enabling.."
    sudo systemsetup -setremotelogin on && echo -e "${I_OK}Remote Login via SSH enabled."
  fi
}

# Check the port where ssh is running (default: 22)
check_ssh_port() {
  local ports
  ports=$(sudo /usr/sbin/sshd -T 2>/dev/null | awk '/^port /{print $2}' | sort -u | xargs)
  if [[ -z "$ports" ]]; then
    echo -e "${I_WARN}Could not obtain effective sshd port(s) via 'sshd -T'"
  elif [[ "$ports" == "22" ]]; then
    echo -e "${I_OK}Effective sshd port is 22"
  else
    echo -e "${I_ERR}sshd is configured to listen on port(s): $ports (expected 22)"; exit 1
  fi
}

# Ensure Executing User is allowed to connect via SSH
check_user_allowed() {
  if dscl . -read /Groups/com.apple.access_ssh >/dev/null 2>&1; then
    if sudo dseditgroup -o checkmember -m "$USER" com.apple.access_ssh >/dev/null 2>&1; then
      echo -e "${I_OK}User $USER is allowed (in com.apple.access_ssh)"
    else
      echo -e "${I_ERR}User $USER is NOT allowed (Remote Login restricted)" && exit 1
    fi
  else
    echo -e "${I_OK}Remote Login allows all users (no com.apple.access_ssh restriction)"
    echo -e "${I_WARN}This is not really secure, but works. Best Practice is to allow only specific users to connect via SSH."
  fi
}

# Ensure MacOS Firewall doesn't block SSH if it's turned on.
ensure_firewall_not_blocking() {
  local firewall_state
  firewall_state="$(sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate)"

  if [[ ! "$firewall_state" == *"disabled"* ]]; then
    echo -e "${I_INFO}MacOS Firewall is enabled."
    echo -e "${I_DO}Running checks to ensure ssh connectivity is not blocked"
    # Disable 'Block all incoming connections'
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setblockall off && echo -e "${I_OK}Disabled: Block all incoming connections"
    # Disable Stealth-Mode
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode off && echo -e "${I_OK}Disabled: Stealth-Mode"
    # Enable 'Automatically allow built-in software to receive incoming connections'
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setallowsigned on && echo -e "${I_OK}Enabled: Automatically allow built-in software to receive incoming connections"
    # Enable 'Automatically allow downloaded signed software to receive incoming connections'
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setallowsignedapp on && echo -e "${I_OK}Enabled: Automatically allow downloaded signed software to receive incoming connections"
    # Allow incoming connections for 'sshd'
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /usr/sbin/sshd && sudo /usr/libexec/ApplicationFirewall/socketfilterfw --unblock /usr/sbin/sshd
    echo -e "${I_OK}Allow Incoming Connections: sshd"
    # Allow incoming connections for 'sshd-keygen-wrapper'
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /usr/libexec/sshd-keygen-wrapper && sudo /usr/libexec/ApplicationFirewall/socketfilterfw --unblock /usr/libexec/sshd-keygen-wrapper
    echo -e "${I_OK}Allow Incoming Connections: sshd-keygen-wrapper"
  else
    echo -e "${I_INFO}MacOS Firewall is disabled."
  fi
}

main() {
  ensure_builtin_ssh 
  ensure_remote_login
  check_ssh_port
  check_user_allowed
  ensure_firewall_not_blocking
  echo -e "-------------------------------------------------------------------------------------------------------------------------------------------"  
  echo -e "${I_INFO}To check ssh connectivity from your control-node to this remote-target run the following command on your control-node container:"
  echo -e "${I_INFO}nc -vz -w2 10.22.22.100 22"
  echo -e "-------------------------------------------------------------------------------------------------------------------------------------------"  
}
main "$@"
