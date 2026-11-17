<div align="center">

# 🛠️ ONESETUP

**Automated workstation setup — Ansible, shell scripts & a bit of magic.**

Bootstrap a fresh Mac into your fully configured dev machine with a single command.
Customize everything in one YAML file — no Ansible knowledge needed.

![Platform](https://img.shields.io/badge/platform-macOS-000000?logo=apple&logoColor=white)
![Ansible](https://img.shields.io/badge/automation-Ansible-EE0000?logo=ansible&logoColor=white)
![Shell](https://img.shields.io/badge/shell-bash%20%2F%20zsh-4EAA25?logo=gnubash&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-blue)

</div>

---

## 📋 Table of Contents

- [Supported Platforms](#️-supported-platforms)
- [Getting Started](#-getting-started)
- [Configuration](#-configuration)
  - [Modules](#modules)
  - [Merge Rules](#merge-rules)
  - [Secrets](#secrets)
  - [Profiles](#profiles)
  - [Environment Variables](#environment-variables)
- [Commands](#-commands)
- [Development](#-development)
  - [Writing a Module](#writing-a-module)
- [Roadmap](#️-roadmap)
- [Contributing](#-contributing)

---

## 🖥️ Supported Platforms

| OS | Architecture | Status |
|---|---|---|
| MacOS | Apple Silicon (arm64) | ✅ Supported |
| MacOS | Intel (x86_64) | 🚧 Not entirely tested yet |
| Linux | x86_64 | 🚧 Planned (*Fedora/Arch/Debian/Ubuntu*) |
| Windows | x86_64 | 🚧 Planned (*Windows 11*) |

---

## 🚀 Getting Started

### 1) Prepare your Mac
*Make sure Homebrew is installed and initialized by your shell config (ZSH: `~/.zprofile` | BASH: `~/.bashrc`)*
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 2) Install the onesetup commands
```bash
bash -c 'curl -fsSL "https://raw.githubusercontent.com/onexbash/onesetup/main/scripts/install.sh" | bash'
```
*Verify with `which onesetup`.*

To install from another branch, pass `--branch` (and take `install.sh` from that branch too):
```bash
bash -c 'curl -fsSL "https://raw.githubusercontent.com/onexbash/onesetup/feat-refactoring/scripts/install.sh" | bash -s -- --branch feat-refactoring'
ONESETUP_BRANCH=feat-refactoring onesetup-init   # playbook from the same branch
```

### 3) Initialize
`onesetup-init` installs the playbook to `$ONESETUP_INSTALL_DIR` and creates your config file from [onesetup.example.yml](./onesetup.example.yml).
Run it again at any time to update onesetup — your config file is never touched.
```bash
onesetup-init
```

### 4) Customize *(optional)*
Edit your config file (`~/.config/onesetup/onesetup.yml`): choose the [modules](#modules) and add your apps, dotfiles, settings, ...
Without changes you get the base setup.

### 5) Encrypt your secrets *(optional)*
```bash
onesetup-vault encrypt --file ~/.ssh/id_ed25519 --target config   # asks for the key, e.g. ssh.identities.id_ed25519
```

### 6) Set device-specific environment variables *(optional)*
```bash
export ONESETUP_HOSTNAME="my-macbook"
export ONESETUP_SSH_KEY="~/.ssh/id_github"   # key used to clone your dotfiles via SSH
```
See [Environment Variables](#environment-variables) for all of them.

### 7) Run
```bash
onesetup
```

---

## 🔧 Configuration

Everything you customize lives in **one file**: `$ONESETUP_CONFIG` (default: `~/.config/onesetup/onesetup.yml`).
It only contains *your* changes — the defaults stay in this repository, so updates never conflict with your config.
Keep the file in your dotfiles repository to use the same setup on every machine.

```yaml
modules: [shell, apps, settings.dock]

apps:
  install:
    brew:
      formulas: [k9s]          # installed on top of the default formulas
      casks: [ghostty, firefox]
      exclude: [lazygit]       # skip a default formula
  autostart: [Ghostty]

settings:
  dock: [Ghostty, Firefox]
```

[onesetup.example.yml](./onesetup.example.yml) shows the common options; each module's `defaults/main.yml` documents all of them.
To run every module with its defaults only, use [onesetup.default.yml](./onesetup.default.yml): `ONESETUP_CONFIG=<install dir>/onesetup.default.yml onesetup`.

### Modules

Only the modules listed under `modules:` run. `apps` runs all parts of the module, `apps.install` only this part.
They always run in the order of this table.

| Module | Parts | What it does | All options |
|---|---|---|---|
| `shell` | `env`, `paths`, `login`, `gui_env` | Global environment variables, `$PATH` (`/etc/paths.d`), login shell, environment variables for GUI apps | [defaults](./modules/shell/defaults/main.yml) |
| `ssh` | `identities`, `config`, `known_hosts`, `authorized_keys` | Rolls out your (encrypted) SSH keys & config, `known_hosts` (overwritten) and `authorized_keys` | [defaults](./modules/ssh/defaults/main.yml) |
| `dotfiles` | `clone`, `link` | Clones your dotfiles repository and symlinks the files into place (existing files are backed up) | [defaults](./modules/dotfiles/defaults/main.yml) |
| `fonts` | `nerdfonts` | Installs Nerd Fonts | [defaults](./modules/fonts/defaults/main.yml) |
| `apps` | `install`, `configure`, `autostart` | Package managers per OS (Homebrew, Mac App Store), manual installs (dmg, pkg, zip, script), gh extensions, Firefox profile, apps started at login | [defaults](./modules/apps/defaults/main.yml) |
| `settings` | `defaults`, `system`, `dock`, `finder`, `keymaps`, `wallpaper`, `browser` | macOS preferences (any `defaults write`), power & startup settings, Dock apps, Finder tags, shortcuts, wallpaper, default browser | [defaults](./modules/settings/defaults/main.yml) |
| `custom` | `tasks` | Runs your own Ansible task files — for everything the modules don't cover | [defaults](./modules/custom/defaults/main.yml) |

Before the modules, the **core** always runs: it checks the environment variables, loads your config, sets the hostname and installs the prerequisites (Xcode Command Line Tools, Rosetta 2, brew versions of bash/zsh/openssh, mas).

### Merge Rules

Your config is merged into the module defaults with three rules:

| You write | Result |
|---|---|
| a list (`formulas: [k9s]`) | **added** to the default list |
| a value (`login: /opt/homebrew/bin/zsh`) | **replaces** the default |
| `exclude: [...]` *(brew, fonts)* | **removes** default entries |

For `settings.defaults`, set a key to `null` to skip a default. Paths may start with `~/`.
Typos are reported: unknown modules stop the run, unknown keys print a warning.

### Secrets

Secrets are stored inline in your config file, encrypted with Ansible Vault (vault id `onesetup`), and decrypted during the run (`onesetup` asks for the vault password, unless `ONESETUP_VAULT_PASS` is set).
```bash
onesetup-vault encrypt --string --target config                        # prompts for the secret & the key
onesetup-vault encrypt --file ~/.ssh/config ssh.config --target config
onesetup-vault encrypt --file ~/.ssh/id_ed25519 --target clipboard     # paste it yourself
```

#### Password Manager References

Secret environment variables (`ONESETUP_SSH_PASS`, `ONESETUP_VAULT_PASS`) can hold a reference instead of the secret.
`onesetup` resolves it when it runs (`run` / `test`) — the last path segment is the field:

| Password manager | Reference | Needs |
|---|---|---|
| Proton Pass | `pass://<vault>/<item>/<field>` | `pass-cli`, logged in |
| KeePassXC | `keepassxc://<group>/.../<entry>/<attribute>` | `keepassxc-cli`, `ONESETUP_KEEPASSXC_DB` (asks for the database password) |
| Bitwarden | `bitwarden://<item>/<field>` | `bw`, unlocked (`export BW_SESSION="$(bw unlock --raw)"`). Field: `password`, `username`, `notes` or a custom field name |

```bash
export ONESETUP_SSH_PASS='pass://Development/GitHub SSH Key/Passphrase'
```

The same references can live in the config file under `secrets:` — any variable name, exported for the run.
Only references are allowed there (no plain secrets), and a set environment variable wins:
```yaml
secrets:
  ONESETUP_VAULT_PASS: "pass://Development/Ansible Vault - onesetup/Secret"
  GITHUB_PAT_PUBLIC_READ: "keepassxc://Development/GitHub PAT/Password" # used by apps.install.manual (GitHub API)
```

### Profiles

One config for several machines: settings under `profiles.<name>` are merged into the config (same [rules](#merge-rules)) when `ONESETUP_PROFILE=<name>` is set.
```yaml
profiles:
  work:
    modules: [ssh]
    apps:
      install:
        brew:
          casks: [microsoft-teams]
```

### Environment Variables

Device-specific settings are environment variables only — everything else belongs into the config file.

| Variable | Default | Description |
|---|---|---|
| `ONESETUP_CONFIG` | `$XDG_CONFIG_HOME/onesetup/onesetup.yml` | Your config file |
| `ONESETUP_PROFILE` | – | [Profile](#profiles) to apply |
| `ONESETUP_HOSTNAME` | – | Hostname to set (HostName, LocalHostName & ComputerName). Unset: keep the current one |
| `ONESETUP_SSH_KEY` | – | Private key to clone the dotfiles repository via SSH (else HTTPS) |
| `ONESETUP_SSH_PASS` | – | Passphrase of that key (or a [password manager reference](#password-manager-references)) |
| `ONESETUP_VAULT_PASS` | – | Vault password (or a [password manager reference](#password-manager-references)). Unset: prompted |
| `ONESETUP_KEEPASSXC_DB` | – | KeePassXC database for `keepassxc://` references |
| `ONESETUP_INSTALL_DIR` | `$XDG_DATA_HOME/onesetup` | Where `onesetup-init` installs the playbook |
| `ONESETUP_STATE_DIR` | `$XDG_STATE_HOME/onesetup` | Ansible collections & state |
| `ONESETUP_BIN_DIR` | `/usr/local/bin` | Where the commands are installed (must be in `$PATH`) |
| `ONESETUP_REPO` | `https://github.com/onexbash/onesetup.git` | Repository `onesetup-init` installs from |
| `ONESETUP_BRANCH` | `main` | Branch `onesetup-init` installs from |
| `ONESETUP_DEV_DIR` | – | Run the playbook from this local checkout instead of the installation (same as `--dev-dir`) |
| `ONESETUP_DEBUG` | `0` | `1`–`3`: verbose Ansible output, `4`: also traces the onesetup scripts |

---

## 💻 Commands

The commands are installed to `$ONESETUP_BIN_DIR` (default `/usr/local/bin`, has to be in your `$PATH`).

### [`onesetup`](./bin/onesetup)
| Command | Description |
| :--- | :--- |
| `onesetup` | Prompts for what to do |
| `onesetup run [options]` | Applies your setup |
| `onesetup test [options] [--diff]` | Shows what would change, without changing anything (`--check`) |
| `onesetup --help` | Usage |

Options: `--include <module,...>` only runs these modules/parts (instead of `modules:`), `--skip <module,...>` skips them (e.g. `--skip apps.autostart,settings`), `--dev-dir <path>` uses a local checkout.

### [`onesetup-init`](./bin/onesetup-init)
Installs or updates the playbook, the commands and the Ansible collections, and creates your config file if it doesn't exist.

### [`onesetup-vault`](./bin/onesetup-vault)
Encrypts secrets with Ansible Vault — into your config file (`--target config`) or to the clipboard (`--target clipboard`). See [Secrets](#secrets) and `onesetup-vault --help`.

---

## 🧪 Development

Test playbook changes without reinstalling:
```bash
onesetup test --dev-dir .   # dry run
onesetup run --dev-dir .
```

Checks:
```bash
yamllint .
ansible-lint
ansible-playbook tests/config.yml   # config loading, profiles, module selection & dispatcher
bash tests/secrets.sh               # password manager references (stub CLIs)
```

### Layout
```
main.yml            # core, then the selected modules
core/               # always runs: env vars, config & run plan, hostname, macOS prerequisites
  vars.yml          # module registry (modules, parts, order) & system facts
  module.yml        # shared by all modules: merges defaults + config into 'cfg', runs the parts
modules/<module>/   # one Ansible role per module
  defaults/main.yml # <module>_defaults: the base setup & documentation of all options
  tasks/main.yml    # includes core/module.yml
  tasks/<part>/     # <os>.yml (osx, linux) and/or all.yml
```

### Writing a Module
1. Create `modules/<name>/defaults/main.yml` with `<name>_defaults:` (every option, documented).
2. Create `modules/<name>/tasks/main.yml` (copy it from another module) and one directory per part with `osx.yml` and/or `all.yml`. Read the merged config from `cfg`.
3. Register the module and its parts in [`core/vars.yml`](./core/vars.yml) (`onesetup_registry`) at the position it should run.

Available variables: `cfg`, `os`, `arch`, `user`, `user_group`, `root_user`, `root_group`, `home`, `xdg_*_home`, `ONESETUP_*`.

---

## 🗺️ Roadmap

- [ ] Linux support (package managers per distribution in `apps.install.managers`)
- [ ] Intel-based MacOS support
- [ ] JSON schema for editor autocompletion of the config file
- [ ] Auto-Installation of manual drivers (printer, ..)

---

## 🤝 Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you'd like to change.

```bash
git clone git@github.com:onexbash/onesetup.git
cd onesetup
yamllint . && ansible-lint && ansible-playbook tests/config.yml && bash tests/secrets.sh
```

---

<div align="center">

Made with ☕ and a healthy dose of shell script magic.

</div>
