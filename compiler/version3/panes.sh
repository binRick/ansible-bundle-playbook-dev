#!/bin/bash
set -e
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

setupWhile(){
    echo "while [ 1 ]; do $@; done"
}
setupTail(){
    echo "tail -f $@"
}



CMD1="$(setupWhile $(setupTail .stderr))"
CMD2="$(setupWhile $(setupTail .stdout))"
CMD3="$(setupWhile $(setupTail .combined.stderr))"
CMD4="$(setupWhile $(setupTail .combined.stdout))"
CMD5="./run.sh"

xpanes \
    -l ev \
    -e \
        "sh -c '$CMD1' 2>/dev/null" \
        "sh -c '$CMD2' 2>/dev/null" \
        "sh -c '$CMD3' 2>/dev/null" \
        "sh -c '$CMD4' 2>/dev/null" \
        "sh -c '$CMD5'"
