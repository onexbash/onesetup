FROM fedora:42
RUN dnf -y install "ansible" "openssh" "openssh-clients"
RUN dnf clean all
SHELL [ "/bin/bash" ]

COPY . /opt/onesetup
WORKDIR /opt/onesetup

ENTRYPOINT [ "ansible-playbook", "main.yml", "--vault-pass-file", "secrets.pass" ]
