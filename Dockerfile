FROM ansible/ansible:latest AS controller
WORKDIR /onesetup
RUN git clone https://github.com/onexbash/onesetup
CMD ["ansible-playbook", "--ask-vault-password", "main.yml"]
