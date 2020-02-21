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
    ansible \
    pexpect \
    tcconfig \
    libtmux \
" 
export MODULES="\
    pyaml \
    setproctitle \
    tmuxp \
    json2yaml \
    paramiko \
    psutil \
" 

exec time ./build.sh
