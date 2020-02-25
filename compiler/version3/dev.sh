#!/bin/bash
set -e
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
exec nodemon \
        -i *.spec -i build -i dist \
        -w *.sh \
        -w *.py \
        -V \
        -e sh,py \
        -x time -- ./run
