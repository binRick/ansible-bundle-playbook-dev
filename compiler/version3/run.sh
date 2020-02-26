#!/bin/bash
set -e
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
export ORIG_DIR="$(pwd)"
source /etc/.ansi
source ../constants.sh
source ../utils.sh
source run-constants.sh
source run-utils.sh
source run-vars.sh

cleanup_compileds
setup_venv
install_borg
ensure_borg
deactivate
load_vars
run_build
save_modules
save_build_to_borg "$DIST_PATH"

normalize_dist_path
test_dist_path
setup_venv
relocate_path


echo "DIST_PATH=$DIST_PATH"
