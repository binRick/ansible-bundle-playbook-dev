#!/bin/bash
set -e

export MODULE_REPOS="
    git+https://github.com/binRick/python3-parse-nagios-status-dat \
"

export BUILD_SCRIPTS="\
    test-hyphen.py \
" 
export _BUILD_SCRIPTS="\
    test.py \
    test1.py \
    tmuxp.py \
    tcshow.py \
    nagios_parser_test.py \
    paramiko_test.py \
" 
#    python3-parse-nagios-status-dat
export _MODULES="\
    ansible \
    pexpect \
    tcconfig \
    libtmux \
    requests \
    halo \
    ansible \
    pyaml \
    tmuxp \
    tcconfig \
" 
export MODULES="\
    setproctitle \
    json2yaml \
    paramiko \
    psutil \
" 

time ./build.sh
