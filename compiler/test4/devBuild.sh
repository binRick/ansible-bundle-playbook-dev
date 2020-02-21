#!/bin/bash
set -e

nodemon --delay 1 --signal SIGTERM \
    -w test*.py -w build.sh -w mangleSpec*.sh -w test_build.sh \
    -V \
    -e sh,py -x -- bash -x ./test_build.sh
