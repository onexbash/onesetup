FROM fedora:42

ARG DOTFILES_DIR
ARG DOTFILES_REPO
ARG ONESETUP_DIR
ARG ONESETUP_DIR2
ARG ONESETUP_REPO

# Install packages with cleanup & registry update
RUN dnf update -y && \
  dnf install -y "git" "ansible" "curl" "sshpass" && \
  dnf clean all

# Create service user with sudo privileges
RUN useradd -ms "/bin/bash" "onesetup" && \
  echo 'onesetup ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
  usermod -aG "wheel" "onesetup"
USER onesetup

# Create working directory
WORKDIR /home/onesetup/src

# Run Control-Node entrypoint script
CMD ["./scripts/controller.sh"]
