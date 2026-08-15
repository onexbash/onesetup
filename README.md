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
| macOS | Apple Silicon (M1 / M2 / M3) | ✅ Supported |
| macOS | Intel | 🚧 Planned |
| Fedora Linux | x86_64 | 🚧 Planned |

---

## 🚀 Getting Started

**1. Run the installation script**

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/onexbash/onesetup/main/scripts/install.sh)"
```

**2. Restart your terminal** to reload the shell configuration.

**3. Run the `onesetup` binary**

```bash
onesetup
```

**4. (Optional) Skip individual roles**

```bash
onesetup --skip "<role_name>, <role_name>"
```

> 💡 Roles are tagged (`dotfiles`, `apps`, `settings`) — pass any combination of tag names to `--skip` to opt out of specific stages.

---

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

All variables live under `group_vars/` and are auto-loaded by `main.yml` — no manual includes required:

| File | Scope | Purpose |
|---|---|---|
| `group_vars/all/*.yml` | All platforms | Shared vars (SSH, general config) |
| `group_vars/osx/*.yml` | macOS only | Brew packages, dock items, OS-specific settings |

Secrets (SSH keys, tokens) are encrypted with **Ansible Vault**:

```bash
ansible-vault edit group_vars/all/ssh.yml
```

You'll be prompted for the vault password (`--ask-vault-pass`) when running `onesetup`.

---

## 🗺️ Roadmap

- [ ] Fedora Linux support
- [ ] Intel-based macOS support
- [ ] Additional CLI parameters
- [ ] Setup wizard to semi-automate secret encryption & storage

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
