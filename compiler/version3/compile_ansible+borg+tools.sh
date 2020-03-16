#!/bin/bash
set -e
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source .ansi

[[ "$NUKE_VENV" == "1" ]] && command rm -rf .venv-1 _borg

export BUILD_MODE='ANSIBLE+BORGS+TOOLS'

if [[ $- == *i* ]]; then
    exec ./run_panes.sh
else
    exec ./run.sh
fi
