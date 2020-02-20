#!/bin/bash
set -e
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
SPEC_FILE="$1"
_SPEC_FILE="$(echo $SPEC_FILE|sed 's/\.spec//g')"
SPEC_NAME="$(echo $SPEC_FILE)"
#SPEC_FILE="$(echo $SPEC_FILE | sed 's/[[::space::]]//g')"
#sed -i 's/-/_/g' $SPEC_FILE
_DIR=$(mktemp -d)

if [[ ! -f "$SPEC_FILE" ]]; then
    echo First Argument must be a spec file
    exit
fi

sed -i 's/^_//g' $SPEC_FILE

#sed -i ".spec_" $SPEC_FILE

ANALYSIS_START_LINE="$(grep '^a = Analysis(' $SPEC_NAME -n|cut -d':' -f1)"
PYZ_START_LINE="$(grep '^pyz = PYZ(' $SPEC_NAME -n|cut -d':' -f1)"
ANALYSIS_END_LINE="$(echo ${PYZ_START_LINE}-1|bc)"
EXE_START_LINE="$(grep '^exe = EXE(p' $SPEC_NAME -n|cut -d':' -f1)"
PYZ_END_LINE="$(echo ${EXE_START_LINE}-1|bc)"
COLLECT_START_LINE="$(grep '^coll = COLLECT(' $SPEC_NAME -n|cut -d':' -f1)"
EXE_END_LINE="$(echo ${COLLECT_START_LINE}-1|bc)"
LAST_LINE="$(wc -l $SPEC_NAME|cut -d' ' -f1)"
COLLECT_END_LINE="$(echo ${LAST_LINE}|bc)"

echo ANALYSIS_START_LINE=$ANALYSIS_START_LINE
echo ANALYSIS_END_LINE=$ANALYSIS_END_LINE

echo PYZ_START_LINE=$PYZ_START_LINE
echo PYZ_END_LINE=$PYZ_END_LINE

echo EXE_START_LINE=$EXE_START_LINE
echo EXE_END_LINE=$EXE_END_LINE

echo COLLECT_START_LINE=$COLLECT_START_LINE
echo COLLECT_END_LINE=$COLLECT_END_LINE

echo LAST_LINE=$LAST_LINE



grep '^block_cipher' $SPEC_FILE > $_DIR/block_cipher.txt
sed -n "${ANALYSIS_START_LINE},${ANALYSIS_END_LINE}p" $SPEC_FILE > $_DIR/ANALYSIS.txt
sed -n "${PYZ_START_LINE},${PYZ_END_LINE}p" $SPEC_FILE > $_DIR/PYZ.txt
sed -n "${EXE_START_LINE},${EXE_END_LINE}p" $SPEC_FILE > $_DIR/EXE.txt
sed -n "${COLLECT_START_LINE},${COLLECT_END_LINE}p" $SPEC_FILE > $_DIR/COLLECT.txt


_F="$(basename $SPEC_FILE)"

sed -i "s/^a = Analysis/${_F}_a = Analysis/g" $_DIR/ANALYSIS.txt
sed -i "s/^pyz = PYZ/${_F}_pyz = PYZ/g" $_DIR/PYZ.txt
sed -i "s/a\./${_F}_a./g" $_DIR/PYZ.txt $_DIR/COLLECT.txt
sed -i "s/^exe = EXE/${_F}_exe = EXE/g" $_DIR/EXE.txt
sed -i "s/pyz,/${_F}_pyz,/g" $_DIR/EXE.txt
sed -i "s/a\./${_F}_a./g" $_DIR/EXE.txt
sed -i "s/^coll = COLLECT/${_F}_coll = COLLECT/g" $_DIR/COLLECT.txt
sed -i "s/exe,/${_F}_exe,/g" $_DIR/COLLECT.txt

(cd $_DIR && sed -i "s/${_SPEC_FILE}.spec_/${_SPEC_FILE}_/g" *.txt)

echo WORKDIR=$_DIR
echo BLOCK_CIPHER=$_DIR/block_cipher.txt
echo PYZ=$_DIR/PYZ.txt
echo ANALYSIS=$_DIR/ANALYSIS.txt
echo EXE=$_DIR/EXE.txt
echo COLLECT=$_DIR/COLLECT.txt

#find $_DIR|xargs cat
