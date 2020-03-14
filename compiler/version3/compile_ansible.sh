#!/bin/bash
set -ex
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source /etc/.ansi

[[ "$NUKE_VENV" == "1" ]] && command rm -rf .venv-1

export BUILD_SCRIPTS="_ansible ansible-playbook ansible-vault ansible-config"
export BUILD_ANSIBLE=1
export BUILD_BORG=0
export MODULES="paramiko"


exec ./run_panes.sh


