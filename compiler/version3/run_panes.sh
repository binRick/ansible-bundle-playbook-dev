#!/bin/bash
set -e
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
ORIG_DIR="$(pwd)"
INITIAL_SLEEP=.1

setupWhile(){
    echo "sleep $INITIAL_SLEEP && while [ 1 ]; do $@; done"
}
setupTail(){
    echo "tail -n0 -f $@"
}



CMD1="$(setupWhile $(setupTail .stderr))"
CMD2="$(setupWhile $(setupTail .stdout))"
CMD3="$(setupWhile $(setupTail .combined.stderr))"
CMD4="$(setupWhile $(setupTail .combined.stdout))"
CMD5="$(setupWhile $(setupTail .combined-compile.stdout))"
CMD6="$(setupWhile $(setupTail .combined-compile.stderr))"
CMD7="sleep 5 && dstat -alp 5 500"
CMD8="time ./run.sh; echo run.sh exited $?"

xpanes \
    -t \
    -s \
    -l ev \
    -B "cd $ORIG_DIR" \
    -e \
        "sh -c '$CMD1' 2>/dev/null" \
        "sh -c '$CMD2' 2>/dev/null" \
        "sh -c '$CMD3' 2>/dev/null" \
        "sh -c '$CMD4' 2>/dev/null" \
        "sh -c '$CMD5' 2>/dev/null" \
        "sh -c '$CMD6' 2>/dev/null" \
        "sh -c '$CMD7'" \
        "sh -c '$CMD8'"
