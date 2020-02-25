#!/bin/bash
set -e
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
exec nodemon \
        -i *.spec -i build -i dist \
        -w . \
        -V \
        -e sh \
        -x time -- ./run
