#!/bin/bash
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source compile_common.sh

export ANSIBLE_MODE=1


source compile_common_run.sh

