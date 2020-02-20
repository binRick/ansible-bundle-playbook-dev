#!/bin/bash
set -e


export BUILD_SCRIPTS="\
    test.py \
    test1.py \
    test2.py \
" 
export MODULES="\
    psutil \
    setproctitle \
    pyaml \
    ansible \
    json2yaml \
    paramiko \
" 

./build.sh
