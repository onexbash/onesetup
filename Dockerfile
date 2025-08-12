FROM fedora:latest as onesetup-controller

# Force image rebuilding when this Dockerfile's content changes.
ARG TIMESTAMP
RUN echo "Timestamp: ${TIMESTAMP}"

# Install packages with cleanup & registry update
RUN dnf update -y && \
  dnf install -y "git" "ansible" "curl" "sshpass" && \
  dnf clean all

# Clone Repository
RUN git clone "https://github.com/onexbash/onesetup.git" "/opt/onesetup"

# Create and use consistent directory
WORKDIR /opt/onesetup

# Verify ansible-playbook exists
RUN test -f /usr/bin/ansible-playbook || (echo "ansible-playbook missing!" && exit 1)

# Run Ansible Playbook
CMD ["/usr/bin/ansible-playbook", "--ask-vault-password", "main.yml"]
