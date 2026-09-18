<div align="center">

# 🛠️ ONESETUP

**Automated workstation setup — Ansible, shell scripts & a bit of magic.**

Bootstrap a fresh Mac into your fully configured dev machine with a single command.

![Platform](https://img.shields.io/badge/platform-macOS-000000?logo=apple&logoColor=white)
![Ansible](https://img.shields.io/badge/automation-Ansible-EE0000?logo=ansible&logoColor=white)
![Shell](https://img.shields.io/badge/shell-bash%20%2F%20zsh-4EAA25?logo=gnubash&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-blue)

</div>

---

## 📋 Table of Contents

- [Supported Platforms](#-supported-platforms)
- [Getting Started](#-getting-started)
- [What It Does](#-what-it-does)
  - [Software Installation](#software-installation)
  - [Dotfiles](#dotfiles)
  - [System Settings](#system-settings)
  - [SSH](#ssh)
- [Configuration](#-configuration)
- [Roadmap](#-roadmap)
- [Contributing](#-contributing)

---

## 🖥️ Supported Platforms

| OS | Architecture | Status |
|---|---|---|
| MacOS | Apple Silicon (arm64) | ✅ Supported |
| MacOS | Intel (x86_64) | ✅ Supported | 🚧 Not entirely tested yet
| Linux | x86_64 | 🚧 Planned | *Fedora/Arch/Debian/Ubuntu*
| Windows | x86_64 | 🚧 Planned | *Windows 11*
---

## 🚀 Getting Started
### 1) Remote Target Preparation 
A Target in this Context is the Device you want to configure, aka [Managed Node](https://docs.ansible.com/projects/ansible/latest/network/getting_started/basic_concepts.html#managed-nodes) in Ansible terms.
Because of some lovely Chicken-Egg-Problems, there are some steps that can't be automated smooth and need to be prepared manually. I'm trying to keep these as little as possible.

#### 1a) MacOS
*Make sure Homebrew is installed on your system and initialized by your Shell Config (ZSH: `~/.zprofile` | BASH: `~/.bashrc`)*
```bash
# Homebrew Installation Script (https://brew.sh)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```
#### 1b) Linux
*COMING SOON / In Testing*

#### 1c) Windows
*Run the official Ansible Target Preperation Script in an elevated Powershell Instance*
```bash
# Fetch Script from Ansible Github Repository
$url = "https://raw.githubusercontent.com/ansible/ansible-documentation/devel/examples/scripts/ConfigureRemotingForAnsible.ps1"
Invoke-WebRequest -Uri $url -OutFile PrepareTargetForAnsible.ps1
# Execute Script
./PrepareTargetForAnsible.ps1
```

### 2) Installation
- Run the installation script
- Replace the username & repo_name variables with the actual values of your Remote Repository (e.g: github):
```bash
username="<USERNAME>" repo_name="<REPOSITORY>" bash -c 'curl -fsSL "https://raw.githubusercontent.com/$username/$repo_name/main/scripts/install.sh" | bash'
```
- Restart your terminal or reload the default shell

### 3) Ansible Vault Encryption
To encrypt your Secrets (e.g: SSH Keys) you can use the `onesetup-vault` command. 
The idea is that you encrypt them via Ansible Vault *(id: onesetup)* 
and store them as a Variable in e.g: [encrypted.yml](./group_vars/all/encrypted.yml) or [ssh.yml](./group_vars/all/ssh.yml).
*Use --target "ansible" to write them directly to the vars-file or "clipboard" to save them to your system clipboard first*
```bash
# Encrypt SSH Key (private & public key)
onesetup-vault encrypt --file "~/.ssh/id_ed25519" --target "ansible"
onesetup-vault encrypt --file "~/.ssh/id_ed25519.pub" --target "ansible"
# Encrypt SSH Config
onesetup-vault encrypt --file "~/.ssh/config" --target "ansible"
# Encrypt everything else you wanna rollout via Ansible
```

### 4) Run Playbook
To apply your Configuration defined in the Ansible Playbook, use the `onesetup` Command.
```bash
# Running without arguments will prompt you for everything that's needed
onesetup
# Skip individual roles
onesetup --skip "<role_name>, <role_name>"
```

> 💡 Roles are tagged (`dotfiles`, `apps`, `settings`) — pass any combination of tag names to `--skip` to opt out of specific stages.

---

## Commands

Once installed, the `onesetup` binaries are available in `/usr/local/bin`. 

> **Note:** `/usr/local/bin` has to be included in your `$PATH` variable.

---

### [`onesetup`](./bin/onesetup)
Applies defined system configurations using Ansible.

| Command | Description |
| :--- | :--- |
| `onesetup` | If run without arguments or subcommands, you will be prompted interactively. |
| `onesetup run [options]` | Executes the Ansible playbook on your target environment. |
| `onesetup run --directory "dev"` | Runs the playbook directly from your local Git repo to test changes without reinstalling |
| `onesetup --help` | Displays command usage and available flags. |

**Available Options for `onesetup run`:**

* `--directory <dev|prod>` (Default: `prod`)
  * `dev`: Executes the playbook from your local **Git Repository Root** (`$ONESETUP_DIR_DEV`). This only works when the command is run from your onesetup git repository.
  * `prod`: Executes the playbook from the **Installation Directory** (`$ONESETUP_DIR`).
* `--roles <role1,role2>` — Runs only the specified comma-separated roles/tags.
* `--skip-roles <role1,...>` — Skips the specified comma-separated roles/tags.

---

### [`onesetup-vault`](./bin/onesetup-vault)
Encrypts or decrypts sensitive variables using Ansible Vault.

| Command | Description |
| :--- | :--- |
| `onesetup-vault` | If run without arguments or subcommands, you will be prompted interactively. |
| `onesetup-vault --help` | Displays usage instructions for vault operations. |
## ⚙️ What It Does

### Software Installation
- Installs Xcode Command Line Tools & accepts the license
- Installs Rosetta 2 (for Apple Silicon compatibility)
- Installs [Homebrew](https://brew.sh)
- Installs casks & formulae defined in [`group_vars/osx/brew.yml`](./group_vars/osx/brew.yml) — languages, CLI tools, apps
- Installs App Store software via `mas` (e.g. Xcode) defined in the `apps` role
- Handles anything that can't be installed via Homebrew or the App Store through custom tasks

### Dotfiles

- Clones your [dotfiles repository](https://github.com/onexbash/dotfiles) to `~/.local/share/dotfiles`
- Symlinks files into place based on the mapping in [`roles/dotfiles/vars/main.yml`](./roles/dotfiles/vars/main.yml)

### System Settings

- Sets macOS Dock items based on [`group_vars/osx/dock.yml`](./group_vars/osx/dock.yml)
- Applies additional system defaults & preferences defined in the [`settings`](./roles/settings) role

### SSH

- Decrypts vault-encrypted SSH keys & known hosts from [`group_vars/all/ssh.yml`](./group_vars/all/ssh.yml)
- Rolls out keys, `authorized_keys`, and `known_hosts` to `~/.ssh` with correct permissions

---

## 🔧 Configuration
For configuration, onesetup will check for a config.yml in the following locations:
$XDG_CONFIG_HOME/onesetup/config.yml
$HOME/.config/onesetup/config.yml

Check [default.config.yml](./default.config.yml) for the Default Values.
See all valid options below: 

```yaml
remote:
  provider: [github|gitlab|bitbucket|azure_devops] # Name of the Provider that stores your onesetup Git Repository
  username: ""
  connection: [https|ssh] # Connection Type for Repository Operations
  project_repo: "" # Repository Name
  dotfiles_repo: "" # Name of a seperate Git Repository that stores all your dotfiles
system:
  os: [macos|linux_fedora|linux_arch|linux_debian|windows] # Operating System (Auto-Detected but can be overridden here)
  username: "" # Name of a User on your system that has sudo privileges but is not the root user
  root_user: "" # Name of the Root user on your system
  config_dir: "" # Config Directory for your config.yml
  install_dir: "" # Installation Directory
  storage_dir: "" # Storage Directory
  dotfiles_dir: "" # Dotfiles Directory used to clone your Dotfiles Repo into and symlink them to the mapped locations
  bin_dir: "" # Directory where the onesetup Binaries are installed to (has to be in $PATH to enable them as commands)
  tmp_dir: "" # Directory for Temporary Files
  user_group: "" # Group of the system user [MacOS Default: "staff" | Linux Default: "?" | Windows Default: "?"] 
  admin_group: "" # Group of the root user [MacOS Default: "wheel" | Linux Default: "wheel" | Windows Default: "admin"]
project:
  development: [true/false]
  debug: [0|1|2|3] # Debug Level for Console Outputs [0: Normal | 1: Info | 2: Verbose | 3: Debug]
```

---

## 🗺️ Roadmap

- [ ] Fedora Linux support
- [ ] Intel-based macOS support
- [ ] Additional CLI parameters
- [ ] Setup wizard to semi-automate secret encryption & storage
- [ ] Auto-Installation of manual drivers (printer, ..)

---

## 🤝 Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you'd like to change.

```bash
git clone git@github.com:onexbash/onesetup.git
cd onesetup
yamllint .   # lint before submitting
```

---

<div align="center">

Made with ☕ and a healthy dose of shell script magic.

</div>
