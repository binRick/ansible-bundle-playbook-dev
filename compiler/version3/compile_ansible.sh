#!/bin/bash
set -ex
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source /etc/.ansi

[[ "$NUKE_VENV" == "1" ]] && command rm -rf .venv-1

time \
    BUILD_SCRIPTS="_ansible ansible-playbook" \
    BUILD_ANSIBLE=1 \
    BUILD_BORG=0 \
    MODULES="paramiko" \
        ./run_panes.sh


