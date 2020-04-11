#!/bin/bash
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source compile_common.sh
__DEBUG_MODE=0
BUILT_DIR=~/BUILT101

        ## LATEST BUILT:
#__BUILT_ID="$(cd $BUILT_DIR && ls -d *|sort -u|sed '1d' | sort -nr|  head -n1)"
        ## NEW BUILD:
__BUILT_ID="$(date +%s)"


STDOUT_FILE=$(mktemp)
[[ ! -d $BUILT_DIR ]] && mkdir -p $BUILT_DIR

export ANSIBLE_MODE=1
export BUILD_BORG=1
export SCRIPTS_BUILD_MODE="ANSIBLE+BORGS+TOOLS"

if [[ "$__DEBUG_MODE" == "1" ]]; then
    STDOUT_FILE=$(pwd)/.o
else
    source compile_common_run.sh | tee $STDOUT_FILE
fi
set -e

COMBINED_TS="$(cat $STDOUT_FILE|  sed 's/\x1b\[[0-9;]*m//g'| tail -n1| cut -d'=' -f2| sed 's/-/\n/g'| tail -n1)"




BUILD_TOOLS_CMD="(cd ~/vpntech-ioncube-encoder && ./BUILD_TOOLS.sh -d $BUILT_DIR/$__BUILT_ID -m all)"
set +e
eval $BUILD_TOOLS_CMD
ec=$?
set -e
echo BUILD_TOOLS_CMD=$BUILD_TOOLS_CMD
echo BUILD_TOOLS_CMD exited $ec
if [[ "$__BUILT_ID" == "" || "$ec" != "0" ]]; then
    ansi --red Invalid built
    exit 666
fi
_POST_CMD="(cd ~/vpntech-ioncube-encoder && time ./ADD_TOOLS.sh  -a .COMBINED-$COMBINED_TS --copy-tarball -t $BUILT_DIR/$__BUILT_ID)"
echo _POST_CMD=$_POST_CMD

set +e
eval $_POST_CMD
ec=$?
set -e
echo _POST_CMD exited $ec
if [[ "$ec" != "0" ]]; then
    ansi --red Invalid built
    exit $ec
fi

exit 0
