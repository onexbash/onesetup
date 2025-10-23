# ONESETUP

## Vision
The idea of this project is to have a System that ensures all of your devices are configured exactly how you want them to be.
The core logic is defined in Ansible Playbooks that store a huge collection of [Desired States](https://www.puppeteers.net/learn/understanding-infrastructure-as-code-iac/#headline-133-5156).
Additionally we use some scripts & container files for automatically setting up & running everything with no effort.

## Prerequesites
- [Homebrew](https://brew.sh/) *(MacOS)*
- [Git](https://git-scm.com/downloads)
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
### Bash
On MacOS & some Linux Distros, the preinstalled bash version is outdated and therefore some functions throw errors where no errors are.
So before you can run the installation script, please install the latest bash version.
```bash
# MacOS (homebrew)
brew install bash
```

## Installation
Run the installation script on the machine that should act as the [Control-Node](https://docs.ansible.com/ansible/latest/network/getting_started/basic_concepts.html#control-node):
```bash
# MacOS
$(brew --prefix)/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/onexbash/onesetup/main/scripts/install.sh)"
# Linux
bash -c "$(curl -fsSL https://raw.githubusercontent.com/onexbash/onesetup/main/scripts/install.sh)"
```
Under the hood, this will:
- ensure prerequesites are satisfied (dependencies, user permissions)
- prepare the filesystem (ensure proper permissions & existance of used directories)
- clone the onesetup repository
- rollout the onesetup binary

## Usage
After Installation, the `onesetup` command should be available on your machine.
This command provides all functionality you need. *See: `onesetup --help`*

For a minimum, you want to do the following:
**1. Apply Configuration**
```bash
onesetup controller run
```

### Encrypt Secrets with Ansible Vault
```bash
onesetup encrypt
onesetup controller
```
This script will automatically spin-up the Ansible Control-Node in a container and applies the Ansible Playbook to the [Remote Targets](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_environment.html).
This Control-Node serves the purpose of applying the Desired States of all playbook tasks to the Remote Targets specified in [inventory.toml](./inventory.toml)

[Remote Target](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_environment.html)

## Encrypt Secrets
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/onexbash/onesetup/main/scripts/encrypt.sh)"
```


## Environment Variables
The following Environment Variables can be set:
```bash
export ONESETUP_DIR="[...]" # sets the installation directory (default: ~/.local/share/onesetup)
export DOTFILES_DIR="[...]" # sets the dotfiles directory (default: ~/.local/share/dotfiles)
export ONESETUP_REPO="[...]" # sets the onesetup repository shortname (default: onexbash/onesetup)
export DOTFILES_REPO="[...]" # sets the dotfiles repository shortname (default: onexbash/dotfiles)
export ANSIBLE_DEBUG="[0/1]" # advanced ansible logs for debugging (default: 0)
```

## Dotfiles
Dotfiles are installed to a source directory and symlinked to the expected location on all targets.
Your Dotfiles need to be published to a separate Repository *e.g:* [onexbash - dotfiles](https://github.com/onexbash/dotfiles).
**WARNING:** *If changes on the local Dotfiles Directory happen, they need to be committed & pushed to main before onesetup can run*
**WARNING:** *Keep in mind that simultanous usage on multiple machines can lead to merge conflicts that need to be resolved manually.*

## Scope
Currently in Scope of this project is:
- Software Installation
- System Settings
- Dotfiles Rollout
- SSH Config
- Network Config
- App Settings (.plist files)
- Firefox Bookmarks (+ Firefox Developer Edition)


## Road Map
- [GitLab](https://gitlab.com), [Bitbucket](https://bitbucket.org), [Azure Devops](https://azure.microsoft.com/de-de/products/devops/) & [Jujutsu](https://github.com/jj-vcs/jj) Support
- [Debian](https://www.debian.org)/[Ubuntu](https://ubuntu.com) Support for the Control-Node Container Host Machine
