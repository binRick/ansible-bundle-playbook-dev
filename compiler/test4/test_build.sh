#!/bin/bash
set -e


export BUILD_SCRIPTS="\
    test.py \
    test1.py \
    tmuxp.py \
    tcshow.py \
    parse_nagios.py \
    paramiko_test.py \
" 
export _BUILD_SCRIPTS="\
" 
#    python3-parse-nagios-status-dat
export _MODULES="\
" 
export MODULES="\
    pyaml \
    ansible \
    tmuxp \
    json2yaml \
    pexpect \
    paramiko \
    psutil \
    tcconfig \
    libtmux \
" 

exec time ./build.sh
