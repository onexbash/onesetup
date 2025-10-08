FROM fedora:42

ARG DOTFILES_DIR
ARG DOTFILES_REPO
ARG ONESETUP_DIR
ARG ONESETUP_REPO

ENV DOTFILES_DIR=$DOTFILES_DIR \
    DOTFILES_REPO=$DOTFILES_REPO \
    ONESETUP_DIR=$ONESETUP_DIR \
    ONESETUP_REPO=$ONESETUP_REPO

# Install packages with cleanup & registry update
RUN dnf install -y "git" "ansible" "curl" "sshpass" && \
    dnf clean all

# Create service user with sudo privileges
RUN useradd -ms "/bin/bash" "onesetup" && \
    echo 'onesetup ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
    usermod -aG "wheel" "onesetup"
USER onesetup

# Create working directory
WORKDIR /home/onesetup/src

# Copy onesetup binary to container
COPY ./bin/onesetup /usr/local/bin/onesetup
# COPY ./bin/* /usr/local/bin/onesetup

# Run Control-Node entrypoint script
CMD ["/usr/local/bin/onesetup controller entrypoint"]
