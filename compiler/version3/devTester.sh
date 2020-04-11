#!/bin/bash
set -e
EXEC_SCRIPT=compile_tester.sh
CMD="./$EXEC_SCRIPT"

nodemon --delay 1 --signal SIGTERM \
    -w test*.py -w build.sh -w mangleSpec*.sh -w test_build.sh \
    -w *.sh -w *.py \
    -i __pycache__ -i */__pycache__ \
    -i dist \
    -V \
    -e sh,py -x $CMD
