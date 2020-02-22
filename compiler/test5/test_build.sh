#!/bin/bash
set -e


export MODULE_REPOS="
    git+https://github.com/binRick/python3-parse-nagios-status-dat \
"
export _MODULE_REPOS="
"

export BUILD_SCRIPTS="\
    ansible-playbook.py \
" 
export _BUILD_SCRIPTS="\
    ansible-config.py \
    ansible-vault.py \
    paramiko_test.py \
    nagios_parser_test.py \
    test-hyphen.py \
    test.py \
    test1.py \
    tmuxp.py \
    tcshow.py \
" 

BASE_MODS="simplejson psutil loguru json2yaml setproctitle pyyaml pyaml"
ADDTL_MODS="terminaltables speedtest-cli netaddr configparser urllib3 jmespath paramiko docopt"

export _MODULES="\
    pexpect \
    tcconfig \
    libtmux \
    halo \
    tmuxp \
    tcconfig \
" 
export MODULES="\
    $BASE_MODS \
    $ADDTL_MODS \
    requests \
    pyaml \
    ansible \
    setproctitle \
    configparser \
    json2yaml \
    paramiko \
    psutil \
" 

./build.sh
