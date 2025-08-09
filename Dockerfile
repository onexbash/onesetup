FROM fedora:latest as onesetup-controller

# Install with cleanup
RUN dnf install -y git ansible && \
  dnf clean all && \
  rm -rf /var/cache/dnf

# Invalidate cache to force image rebuild when file changes happen.
ADD https://raw.githubusercontent.com/onexbash/onesetup/main/README.md /tmp/watch

# Clone Repository
RUN git clone "https://github.com/onexbash/onesetup.git" "/opt/onesetup"

# Create and use consistent directory
WORKDIR /opt/onesetup

# Verify ansible-playbook exists
RUN test -f /usr/bin/ansible-playbook || (echo "ansible-playbook missing!" && exit 1)

# Run Ansible Playbook
CMD ["/usr/bin/ansible-playbook", "--ask-vault-password", "main.yml"]
