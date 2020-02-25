#!/bin/bash
set -e
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
exec nodemon \
        -i *.spec -i build -i dist \
        -w run-vars.sh -w run-constants.sh -w run-utils.sh -w dev.sh -w run_panes.sh \
        -w ansible-playbook.py -w scripts/*.py \
        -V \
        -e sh,py \
        -x time -- ./run
