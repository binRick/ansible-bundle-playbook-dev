#!/bin/bash
export SCRIPTS_BUILD_MODE='ANSIBLE+BORGS+TOOLS'
set -e
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source .ansi


if [[ "$PANE_MODE" == "1" || $- == *i* ]]; then
    ansi --green "Running in pane mode"
    exec ./run_panes.sh
else
    ansi --yellow "Running in standard mode"
    exec ./run.sh
fi
