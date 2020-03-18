#!/bin/bash
set -e
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
ORIG_DIR="$(pwd)"
source run_panes-utils.sh
source run_panes-constants.sh

CMD3="$(setupWhile $(setupTail ~/.*stderr* $ORIG_DIR/.*stdout*))"
CMD4="$(setupWhile $(setupTail ~/.*stdout* $ORIG_DIR/.*stderr*))"
CMD_dstat="sleep 5 && command dstat -alp --top-cpu 5 500"
CMD_run="time ./run.sh; echo run.sh exited $?"

xpanes \
    -t \
    -d \
    -l ev \
    -s \
    -t \
    -B "cd $ORIG_DIR" \
    -e \
        "sh -c '$CMD3' 2>/dev/null" \
        "sh -c '$CMD4' 2>/dev/null" \
        "$CMD_dstat" \
        "sh -c '$CMD_run'"
