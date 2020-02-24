#!/bin/bash
set -e
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
export ORIG_DIR="$(pwd)"
source /etc/.ansi
source run-constants.sh
source run-utils.sh

setup_venv
deactivate
load_vars
run_build


echo DIST_PATH=$DIST_PATH

save_modules

mv $DIST_PATH ${DIST_PATH}.t
mkdir $DIST_PATH
mv ${DIST_PATH}.t $DIST_PATH/ansible-playbook
echo $ANSIBLE_CFG_B64|base64 -d > $DIST_PATH/ansible-playbook/ansible.cfg

echo "DIST_PATH=$DIST_PATH"



