# ONESETUP

### Vision
The idea of this project is to have a System that ensures all of your devices are configured exactly how you want them to be.
The core logic is defined in Ansible Playbooks that store a huge collection of [Desired States](https://www.puppeteers.net/learn/understanding-infrastructure-as-code-iac/#headline-133-5156).
Additionally we use some scripts & container files for automatically setting up & running everything with no effort.

### Scope
Currently in Scope of this project is:
- Software Installation
- System Settings
- Dotfiles Rollout
- SSH Config
- Network Config
- App Settings (.plist files)
- Firefox Bookmarks (+ Firefox Developer Edition)

### Installation
Run the install script on the machine you wanna run your [Control-Node](https://docs.ansible.com/ansible/latest/network/getting_started/basic_concepts.html) on.
It will automatically spin up a Container via [podman](https://podman.io/) where the [onesetup](https://github.com/onexbash/onesetup) playbook is executed from.
```bash
    curl -sSL https://raw.githubusercontent.com/onexbash/onesetup/main/scripts/install.sh | bash
```

### Usage

To apply the desired states from the playbook on your target machines, run the execute script where you previously installed the control-node.
```bash
    curl -sSL https://raw.githubusercontent.com/onexbash/onesetup/main/scripts/execute.sh | bash
```

### Dotfiles
Dotfiles are installed to a [source directory](/opt/onesetup) and symlinked to the expected location on all targets.
Your Dotfiles need to be published to a separate Remote Repository.
The Dotfiles Mapping has to be defined in [./config.yml] of the [onesetup](https://github.com/onexbash/onesetup) Repository.

**WARNING:** *If changes on the local Dotfiles Directory happen, they need to be committed & pushed to main before onesetup can run*
**WARNING:** *Keep in mind that simultanous usage on multiple machines can lead to merge conflicts that need to be resolved manually.*


### Road Map
- [GitLab](https://gitlab.com), [Bitbucket](https://bitbucket.org), [Azure Devops](https://azure.microsoft.com/de-de/products/devops/) & [Jujutsu](https://github.com/jj-vcs/jj) Support
- [Debian](https://www.debian.org)/[Ubuntu](https://ubuntu.com) Support for the Control-Node Container Host Machine
