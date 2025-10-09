FROM fedora:42

ARG DOTFILES_DIR
ARG DOTFILES_REPO
ARG ONESETUP_DIR
ARG ONESETUP_REPO
ARG ANSIBLE_DEBUG

ENV DOTFILES_DIR=$DOTFILES_DIR \
  DOTFILES_REPO=$DOTFILES_REPO \
  ONESETUP_DIR=$ONESETUP_DIR \
  ONESETUP_REPO=$ONESETUP_REPO \
  ANSIBLE_DEBUG=$ANSIBLE_DEBUG

# Set Working Directory
WORKDIR /home/onesetup/src

# Create service user with sudo privileges
RUN useradd -ms "/bin/bash" "onesetup" && \
  echo 'onesetup ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
  usermod -aG "wheel" "onesetup"
USER onesetup

# Install packages
RUN dnf install -y "git" "ansible" "curl" "sshpass" && \
  dnf clean all

# Run Control-Node entrypoint script
CMD ["scripts/entrypoint.sh"]
