#!/bin/bash
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
set -e
time DEBUG_CMD=0 ANSIBLE_VERSION=2.8.8 BUILD_ONLY=1 ./compileAnsible.sh
