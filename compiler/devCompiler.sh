#!/bin/bash
set -e
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

nodemon -w . -e sh --delay 1 --signal SIGTERM -x time -- ./COMPILER.sh
