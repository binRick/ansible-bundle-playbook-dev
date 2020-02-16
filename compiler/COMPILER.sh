#!/bin/bash 
set -e

if [[ "$REPO_PATH" == "" ]]; then
    REPO_PATH=~/public_html/whmcs/modules/addons/vpntech/submodules/ansible-bundle-playbook-dev
fi

if [[ -d /home/COMPILER ]]; then
    sudo rm -rf /home/COMPILER
fi

if [[ ! -d /home/COMPILER ]]; then
    sudo mkdir -p /home/COMPILER
    sudo chown -R COMPILER:COMPILER /home/COMPILER 
    sudo chmod -R 700 /home/COMPILER
fi

#    ~COMPILER/.venv* \

sudo rm -rf \
    ~COMPILER/ansible-bundle-playbook-dev \
    /tmp/__pycache__ \
    ~COMPILER/build \
    /tmp/PATCHED_MAIN_BINARIES.txt


sudo rsync $REPO_PATH ~COMPILER/. -ar

sudo -Hi -u COMPILER \
    BUILD_ONLY=1 \
    MANGLE_MAIN_BINARY=1 \
    ANSIBLE_VERSION=2.8.8 \
    DEBUG_MAIN_BINARY_BUILD=0 \
    INCLUDE_ANSIBLE_TOOLS=0 \
        $REPO_PATH/compiler/compileAnsible.sh | tee ~/.ansible-bundler-log-$(date +%s).txt
