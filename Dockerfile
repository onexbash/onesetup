FROM ansible/ansible:fedora25 AS controller
RUN dnf install git

WORKDIR /onesetup
RUN git clone https://github.com/onexbash/onesetup
CMD ["ansible-playbook", "--ask-vault-password", "main.yml"]
