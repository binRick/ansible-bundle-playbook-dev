#!/bin/bash
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source compile_common.sh

export ANSIBLE_MODE=0
export BUILD_BORG=0
export SCRIPTS_BUILD_MODE=tester


source compile_common_run.sh

