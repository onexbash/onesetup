FROM fedora:latest as onesetup-controller

# Force image rebuilding when this Dockerfile's content changes.
ARG TIMESTAMP
RUN echo "Timestamp: ${TIMESTAMP}"

# Install packages with cleanup & registry update
RUN dnf update -y && \
  dnf install -y "git" "ansible" "iputils" "curl" "sshpass" "traceroute" && \
  dnf clean all

RUN ping onexmac-cratos.local
RUN traceroute 10.22.22.100
RUN traceroute 8.8.8.8
# # TODO: DEBUG, remove later
# RUN ping -c 4 10.22.22.100
# 
# # Clone Repository
# RUN git clone "https://github.com/onexbash/onesetup.git" "/opt/onesetup"
# 
# # Create and use consistent directory
# WORKDIR /opt/onesetup
# 
# # Verify ansible-playbook exists
# RUN test -f /usr/bin/ansible-playbook || (echo "ansible-playbook missing!" && exit 1)
# 
# # Run Ansible Playbook
# CMD ["/usr/bin/ansible-playbook", "--ask-vault-password", "main.yml"]
# 
