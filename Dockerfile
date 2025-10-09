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

# Ensure bin dirs exist in $PATH
ENV PATH="/usr/local/bin:/usr/bin:/bin:${PATH}"

# Install packages
RUN dnf install -y "git" "ansible" "curl" "sshpass" && \
  dnf clean all

# Create service user with sudo privileges
RUN useradd -ms "/bin/bash" "onesetup" && \
  echo 'onesetup ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
  usermod -aG "wheel" "onesetup"
USER onesetup

# Create working directory
WORKDIR /home/onesetup/src

# Copy binaries to container
COPY ./bin/* /usr/local/bin

# Run Control-Node entrypoint script
CMD ["onesetup controller entrypoint"]
