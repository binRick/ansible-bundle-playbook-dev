#!/bin/bash 
set -e
NUKE_DIR=0

if [[ "$REPO_PATH" == "" ]]; then
    REPO_PATH=~/public_html/whmcs/modules/addons/vpntech/submodules/ansible-bundle-playbook-dev
fi

if [[ "$NUKE_DIR" == "1" ]]; then
    if [[ -d /home/COMPILER ]]; then
        sudo mv /home/COMPILER /home/.COMPILER-tmp
        if [[ -d /home/.COMPILER-tmp ]]; then sudo rm -rf /home/.COMPILER-tmp; fi
    fi
fi

if [[ ! -d /home/COMPILER ]]; then
    sudo mkdir -p /home/COMPILER
fi

if [[ -d /home/.COMPILER-tmp ]]; then
    sudo mv /home/.COMPILER-tmp/.ansible-bundler-log-*.txt /home/COMPILER/.
    sudo rm -rf /home/.COMPILER-tmp
fi

sudo chown -R COMPILER:COMPILER /home/COMPILER 
sudo chmod -R 700 /home/COMPILER

sudo rm -rf \
    ~COMPILER/ansible-bundle-playbook-dev \
    /tmp/__pycache__ \
    ~COMPILER/build \
    ~COMPILER/.*.txt \
    ~COMPILER/*.spec \
    /tmp/*.txt


sudo rsync $REPO_PATH ~COMPILER/. -ar

sudo -Hi -u COMPILER \
    BUILD_ONLY=1 \
    MANGLE_MAIN_BINARY=1 \
    ANSIBLE_VERSION=2.8.8 \
    DEBUG_MAIN_BINARY_BUILD=0 \
    INCLUDE_ANSIBLE_TOOLS=0 \
        $REPO_PATH/compiler/compileAnsible.sh 2>&1 | tee ~/.ansible-bundler-log-$(date +%s).txt
