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

# Check if environment variables are exported to the container session
RUN echo "$ONESETUP_DIR"

# Verify & Run Ansible Playbook
CMD ["/usr/bin/ansible-playbook", "--ask-vault-password", "main.yml"]
