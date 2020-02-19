#!/bin/bash
set -e
export DEV_FILES="test.py test1.py test2.py"

nodemon --delay 1 --signal SIGTERM \
    -w test*.py -w build.sh -w mangleSpec*.sh \
    -V \
    -e sh,py -x -- bash -x ./build.sh 
