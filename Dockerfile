FROM fedora:42

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

ARG ONESETUP_DIR
RUN echo "Build-time ONESETUP_DIR: $ONESETUP_DIR" && \
    echo "Current working directory: $(pwd)"

# Verify & Run Ansible Playbook
# CMD ["/usr/bin/ansible-playbook", "--ask-vault-password", "main.yml"]

CMD ["/bin/bash", "-c", "echo 'Runtime ONESETUP_DIR: $ONESETUP_DIR'; /usr/bin/ansible-playbook --ask-vault-password main.yml"]
