#!/bin/bash
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source compile_common.sh
__DEBUG_MODE=0
BUILT_DIR=~/BUILT1488

        ## LATEST BUILT:
#__BUILT_ID="$(cd $BUILT_DIR && ls -d *|sort -u|sed '1d' | sort -nr|  head -n1)"
        ## NEW BUILD:
export __BUILT_ID="$(date +%s)"


STDOUT_FILE=~/.stdout-tools

[[ ! -d $BUILT_DIR ]] && mkdir -p $BUILT_DIR

export ANSIBLE_MODE=1
export BUILD_BORG=1
export SCRIPTS_BUILD_MODE="ANSIBLE+BORGS+TOOLS"

if [[ "$__DEBUG_MODE" == "1" ]]; then
    STDOUT_FILE=$(pwd)/.o
else
    _exec=compile_common_run.sh
    source $_exec | tee $STDOUT_FILE
    ec=$?
    if [[ "$ec" != "0" ]]; then
        ansi --red "Invalid Exit code $ec from \"$_exec\""
        exit $ec
    fi
fi
set -e

#COMBINED_TS="$(cat $STDOUT_FILE|  sed 's/\x1b\[[0-9;]*m//g'| tail -n1| cut -d'=' -f2| sed 's/-/\n/g'| tail -n1)"
COMBINED_TS=$(cd ~/vpntech-ioncube-encoder/ansible-bundle-playbook-dev/compiler/version3 && borg --lock-wait 30 list --format="{name}{NEWLINE}" --last 1| cut -d'-' -f2)




BUILD_TOOLS_CMD="(cd ~/vpntech-ioncube-encoder && ./BUILD_TOOLS.sh -d $BUILT_DIR/$__BUILT_ID -m all)"
echo $BUILD_TOOLS_CMD






set +e
eval $BUILD_TOOLS_CMD
ec=$?
if [[ "$ec" != "0" ]]; then
    ansi --red "Invalid Exit code $ec from \"$BUILD_TOOLS_CMD\""
    exit $ec
fi
set -e
echo BUILD_TOOLS_CMD=$BUILD_TOOLS_CMD
echo BUILD_TOOLS_CMD exited $ec
if [[ "$__BUILT_ID" == "" || "$ec" != "0" ]]; then
    ansi --red Invalid built
    exit 666
fi
_POST_CMD="(time ~/vpntech-ioncube-encoder/ADD_TOOLS.sh  -a .COMBINED-$COMBINED_TS --copy-tarball -t $BUILT_DIR/$__BUILT_ID)"
echo _POST_CMD=$_POST_CMD

exit
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
