#!/bin/bash
set -e
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source /etc/.ansi

[[ "$NUKE_VENV" == "1" ]] && command rm -rf .venv-1

export ANSIBLE_MODE=1

exec ./run_panes.sh
