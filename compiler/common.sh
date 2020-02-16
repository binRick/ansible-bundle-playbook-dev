nukeTmp(){
  sudo rm -rf \
    ~COMPILER/ansible-bundle-playbook-dev \
    /tmp/__pycache__ \
    ~COMPILER/build \
    ~COMPILER/.venv* \
    ~COMPILER/.*.txt \
    ~COMPILER/*.spec \
    /tmp/*.txt
}
