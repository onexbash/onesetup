FROM fedora:latest as onesetup-controller

# Force image rebuilding when this Dockerfile's content changes.
ARG TIMESTAMP
RUN echo "Timestamp: ${TIMESTAMP}"

# Install packages with cleanup & registry update
RUN dnf update -y && \
  dnf install -y "git" "ansible" "curl" "sshpass" && \
  dnf clean all

# Create service user with sudo privileges
RUN useradd -ms "/bin/bash" "onesetup" && \
    echo 'onesetup ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
    usermod -aG "wheel" "onesetup"
USER onesetup

# Clone Repository
RUN git clone "https://github.com/onexbash/onesetup.git" "/home/onesetup/src"

# Create and use consistent directory
WORKDIR /home/onesetup/src

# Verify & Run Ansible Playbook
RUN test -f /usr/bin/ansible-playbook || (echo "ansible-playbook missing!" && exit 1)
CMD ["/usr/bin/ansible-playbook", "--ask-vault-password", "main.yml"]
