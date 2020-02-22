#!/bin/bash
set -e


export MODULE_REPOS="
    git+https://github.com/binRick/python3-parse-nagios-status-dat \
"
export _MODULE_REPOS="
"

export BUILD_SCRIPTS="\
    ansible-playbook.py \
    ansible-config.py \
    ansible-vault.py \
    paramiko_test.py \
    nagios_parser_test.py \
" 
export _BUILD_SCRIPTS="\
    test-hyphen.py \
    test.py \
    test1.py \
    tmuxp.py \
    tcshow.py \
" 

export _MODULES="\
    pexpect \
    tcconfig \
    libtmux \
    halo \
    tmuxp \
    tcconfig \
" 
export MODULES="\
    requests \
    pyaml \
    ansible \
    setproctitle \
    configparser \
    json2yaml \
    paramiko \
    psutil \
" 

time ./build.sh
