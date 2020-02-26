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

if [[ "$BUILD_BORG" == "1" ]]; then
    MYBORG_PATH="$DIST_PATH/ansible-playbook/bin/MYBORG"
    echo doPassphraseTests "$MYBORG_PATH"
fi

>&2 ansi --green "Disk Usage: $(du --max-depth=1 -h $DIST_PATH)"
>&2 ansi --green "File Count: $(find $DIST_PATH -type f|wc -l)"
>&2 ansi --green "Directory Count: $(find $DIST_PATH -type d|wc -l)"

echo "DIST_PATH=$DIST_PATH"
