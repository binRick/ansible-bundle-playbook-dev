#!/bin/bash
set -e
#grep hidden-import .combined-spec-cmd.sh|cut -d'"' -f2
./getModules.sh|grep "${1}" >> ../EXCLUDED_ANSIBLE_MODULES.txt
