#!/bin/bash
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source compile_common.sh


__DEBUG_MODE=0
BUILT_DIR=~/BUILT69691
__BUILT_ID="$(date +%s)"

STDOUT_FILE=$(mktemp)
[[ ! -d $BUILT_DIR ]] && mkdir -p $BUILT_DIR

export ANSIBLE_MODE=0
export BUILD_BORG=0
export SCRIPTS_BUILD_MODE=tester

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
_POST_CMD="(time ~/vpntech-ioncube-encoder/ADD_TOOLS.sh  -a .COMBINED-$COMBINED_TS -t $BUILT_DIR/$__BUILT_ID)"
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
