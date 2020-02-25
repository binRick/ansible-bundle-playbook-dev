#!/bin/bash
set -e
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd $1
for x in $BUILD_SCRIPTS; do
    x=$(basename $x .py)
    ./$x --version
done
#./paramiko_test.py > .status.dat
#NAGIOS_STATUS_FILE_PATH=.status.dat ./nagios_parser_test.py|jq
