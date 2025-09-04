# ONESETUP

## Vision
The idea of this project is to have a System that ensures all of your devices are configured exactly how you want them to be.
The core logic is defined in Ansible Playbooks that store a huge collection of [Desired States](https://www.puppeteers.net/learn/understanding-infrastructure-as-code-iac/#headline-133-5156).
Additionally we use some scripts & container files for automatically setting up & running everything with no effort.

## Scope
Currently in Scope of this project is:
- Software Installation
- System Settings
- Dotfiles Rollout
- SSH Config
- Network Config
- App Settings (.plist files)
- Firefox Bookmarks (+ Firefox Developer Edition)

## Get Started
Run the following command on a machine with local network access to your remote-targets:
```bash
    curl -sSL https://raw.githubusercontent.com/onexbash/onesetup/main/scripts/onesetup.sh | bash
```
This script will automatically spin-up the Ansible Control-Node in a container.
This Control-Node serves the purpose of applying the Desired States of all playbook tasks to the Remote Targets specified in [inventory.toml](./inventory.toml)

## Dotfiles
Dotfiles are installed to an [origin](/opt/dotfiles) and symlinked to the expected location on all targets.
Your Dotfiles need to be published to a separate Repository *e.g:* [onexbash - dotfiles](https://github.com/onexbash/dotfiles).
**WARNING:** *If changes on the local Dotfiles Directory happen, they need to be committed & pushed to main before onesetup can run*
**WARNING:** *Keep in mind that simultanous usage on multiple machines can lead to merge conflicts that need to be resolved manually.*

## Road Map
- [GitLab](https://gitlab.com), [Bitbucket](https://bitbucket.org), [Azure Devops](https://azure.microsoft.com/de-de/products/devops/) & [Jujutsu](https://github.com/jj-vcs/jj) Support
- [Debian](https://www.debian.org)/[Ubuntu](https://ubuntu.com) Support for the Control-Node Container Host Machine
