FROM fedora:42
# Pass Environment Variables
ARG DOTFILES_DIR
ARG DOTFILES_REPO
ARG ONESETUP_DIR
ARG ONESETUP_REPO
ENV DOTFILES_DIR=$DOTFILES_DIR \
  DOTFILES_REPO=$DOTFILES_REPO \
  ONESETUP_DIR=$ONESETUP_DIR \
  ONESETUP_REPO=$ONESETUP_REPO

# Set Working Directory
WORKDIR /home/onesetup/src

# Add onesetup bin dir to $PATH
ENV PATH="/home/onesetup/src/bin:${PATH}"

# Install packages
RUN dnf install -y "git" "ansible" "curl" "sshpass" && \
  dnf clean all

# Run Control-Node entrypoint script
CMD ["bin/onesetup-controller", "--entrypoint"]
