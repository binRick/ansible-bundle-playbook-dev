#!/bin/bash
set -e
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
export ORIG_DIR="$(pwd)"
. setup.sh

nesting_success() {
    local args=(
        - "Cleanup Past Compilations"       cleanup_compileds
        - "Setup Virtual Environment"       setup_venv
        - "Install Borg"       install_borg
        - "Validate Borg"       ensure_borg
        - "Deactivate Virtual Environment"       deactivate
        - "Load Variables"       load_vars
        - "Run Build"       run_build
        - "Save Modules"       save_modules
        - "Normalize Dist Path"       test_dist_path
        - "Setup Virtual Environment"       setup_venv
        - "Relocate Dist Path"       relocate_path
        - "Print Summary"       summary
    )
    local _args=(
        - "Save Modules to Borg"       save_build_to_borg "$DIST_PATH"
        - "Test Borg"       test_borg
    )
    local __args=(
        - "Task A2"               concurrent
            -- "Task B1"          concurrent
                --- "Task C1"     sleep 1.0
                --- "Task C2"     sleep 2.0 1
            -- "Task B2"          sleep 3.0
        - "Task A3"               sleep 4.0
    )

    concurrent "${args[@]}"
}

nesting_success
echo OK
echo "DIST_PATH=$DIST_PATH"
exit













cleanup_compileds
setup_venv
install_borg
ensure_borg
deactivate
load_vars
run_build
save_modules
#save_build_to_borg "$DIST_PATH"
normalize_dist_path
test_dist_path
setup_venv
relocate_path
#test_borg
summary

echo "DIST_PATH=$DIST_PATH"
