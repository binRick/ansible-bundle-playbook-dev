#!/bin/bash
set -e
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source /etc/.ansi

[[ "$NUKE_VENV" == "1" ]] && command rm -rf .venv-1

export BUILD_MODE='ANSIBLE+BORGS+TOOLS'

#exec ./run.sh
exec ./run_panes.sh
