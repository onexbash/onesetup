FROM fedora:latest
RUN dnf install git
RUN dnf install ansible
WORKDIR /onesetup
RUN git clone https://github.com/onexbash/onesetup
CMD ["ansible-playbook", "--ask-vault-password", "main.yml"]
