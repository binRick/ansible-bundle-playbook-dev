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
CMD7="$(setupWhile $(setupTail .combined-mkspec.stderr))"
CMD8="$(setupWhile $(setupTail .combined-mkspec.stdout))"
CMD9="$(setupWhile $(setupTail .combined-spec-cmd.sh))"
CMD10="$(setupWhile $(setupTail .bin_jinja.stderr))"
CMD11="$(setupWhile $(setupTail .bin_jinja-cmd.sh))"
#CMD_count_add_datas="watch -n 10 \"echo -e "add-data lines in .combined-spec-cmd.sh:\" && grep add-data .combined-spec-cmd.sh -c""
CMD_dstat="sleep 5 && command dstat -alp 5 500"
CMD_run="time ./run.sh; echo run.sh exited $?"
CMD_nodemon_run="nodemon --delay 1 -V -w run*.sh -e sh -x ./run.sh"

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
        "sh -c '$CMD7' 2>/dev/null" \
        "sh -c '$CMD8' 2>/dev/null" \
        "sh -c '$CMD9' 2>/dev/null" \
        "sh -c '$CMD10' 2>/dev/null" \
        "sh -c '$CMD_dstat'" \
        "sh -c '$CMD_nodemon_run'"
        #"sh -c '$CMD_run'"
