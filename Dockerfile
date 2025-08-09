FROM fedora:latest
RUN dnf install git
RUN dnf install ansible
WORKDIR /onesetup
RUN git clone https://github.com/onexbash/onesetup
CMD ["/usr/bin/ansible-playbook", "--ask-vault-password", "/opt/onesetup/main.yml"]
