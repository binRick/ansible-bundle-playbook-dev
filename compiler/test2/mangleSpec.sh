#!/bin/bash
set -e
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
SPEC_FILE=$1
_DIR=$(mktemp -d)

if [[ ! -f "$SPEC_FILE" ]]; then
    echo First Argument must be a spec file
    exit
fi

ANALYSIS_START_LINE="$(grep '^a = Analysis(' test1.spec -n|cut -d':' -f1)"
PYZ_START_LINE="$(grep '^pyz = PYZ(' test1.spec -n|cut -d':' -f1)"
ANALYSIS_END_LINE="$(echo ${PYZ_START_LINE}-1|bc)"
EXE_START_LINE="$(grep '^exe = EXE(p' test1.spec -n|cut -d':' -f1)"
PYZ_END_LINE="$(echo ${EXE_START_LINE}-1|bc)"
COLLECT_START_LINE="$(grep '^coll = COLLECT(' test1.spec -n|cut -d':' -f1)"
EXE_END_LINE="$(echo ${COLLECT_START_LINE}-1|bc)"
LAST_LINE="$(wc -l test1.spec|cut -d' ' -f1)"
COLLECT_END_LINE="$(echo ${LAST_LINE}-1|bc)"

echo -e "\n\n"
echo ANALYSIS_START_LINE=$ANALYSIS_START_LINE
echo ANALYSIS_END_LINE=$ANALYSIS_END_LINE

echo PYZ_START_LINE=$PYZ_START_LINE
echo PYZ_END_LINE=$PYZ_END_LINE

echo EXE_START_LINE=$EXE_START_LINE
echo EXE_END_LINE=$EXE_END_LINE

echo COLLECT_START_LINE=$COLLECT_START_LINE
echo COLLECT_END_LINE=$COLLECT_END_LINE

echo LAST_LINE=$LAST_LINE

echo -e "\n\n"


cmd="sed -n \"${ANALYSIS_START_LINE},${ANALYSIS_END_LINE}p\" test1.spec"
eval $cmd > $_DIR/ANALYSIS.txt

grep '^block_cipher' $SPEC_FILE > $_DIR/block_cipher.txt
sed -n "${PYZ_START_LINE},${PYZ_END_LINE}p" test1.spec > $_DIR/PYZ.txt
sed -n "${EXE_START_LINE},${EXE_END_LINE}p" test1.spec > $_DIR/EXE.txt
sed -n "${COLLECT_START_LINE},${COLLECT_END_LINE}p" test1.spec > $_DIR/COLLECT.txt



echo OK
echo -e "\n\n"

ls -al $_DIR
echo -e "\n\n"
wc -l $_DIR/*.txt
echo -e "\n\n"
echo Work Directory:
echo $_DIR
echo -e "\n\n"
