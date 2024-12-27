# ONESETUP

automated workstation setup playbook using ansible, shell scripts & some magic

## Supported Platforms

- MacOS M1, M2, M3

## Getting Started

1. Run installation script
```bash
   "bash" -c "$(curl -fsSL https://raw.githubusercontent.com/onexbash/onesetup/main/bin/install)"
```
2. Restart Terminal to reload shell config
3. Execute onesetup binary
```bash
    onesetup
```
4. (optional) skip individual roles using --skip
```bash
    onesetup --skip "<role_name>, <role_name>"
```

## Roadmap

- Fedora Linux Support
- Intel Based MacOS Support
- Additional command parameters
- Semi-Automate the secret encryption & storage process with a wizard
