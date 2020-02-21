#!/bin/bash
set -e

export MODULE_REPOS="
    git+https://github.com/binRick/python3-parse-nagios-status-dat \
"

export BUILD_SCRIPTS="\
    paramiko_test.py \
    ansible-config.py \
" 
export _BUILD_SCRIPTS="\
    test-hyphen.py \
    test.py \
    nagios_parser_test.py \
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
    setproctitle \
    configparser \
    json2yaml \
    paramiko \
    psutil \
    ansible \
" 

time ./build.sh
