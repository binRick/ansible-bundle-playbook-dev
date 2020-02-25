#!/bin/bash
set -e
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
export ORIG_DIR="$(pwd)"
source /etc/.ansi
source run-constants.sh
source run-utils.sh

ensure_borg
setup_venv
deactivate
load_vars
run_build
save_modules
save_build_to_borg "$DIST_PATH"

COMMENT="$(parse_get_borg_repo_comment "$(basename $DIST_PATH)")"
echo "COMMENT=$COMMENT"

echo REPO_MODULES=
get_borg_repo_modules "$(basename $DIST_PATH)"

mv $DIST_PATH ${DIST_PATH}.t
mkdir $DIST_PATH
mv ${DIST_PATH}.t $DIST_PATH/ansible-playbook
echo $ANSIBLE_CFG_B64|base64 -d > $DIST_PATH/ansible-playbook/ansible.cfg

echo "DIST_PATH=$DIST_PATH"



