#!/bin/bash
set -e
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
export ORIG_DIR="$(pwd)"
for S in /etc/.ansi ../constants.sh ../utils.sh run-constants.sh run-vars.sh run-utils.sh ../../submodules/bash-concurrent/concurrent.lib.sh; do source $S; done




nesting_success() {
    local args=(
        - "Task A1"               my_sleep 2.0
        - "Task A2"               concurrent
            -- "Task B1"          concurrent
                --- "Task C1"     my_sleep 1.0
                --- "Task C2"     my_sleep 2.0 1
            -- "Task B2"          my_sleep 3.0
        - "Task A3"               my_sleep 4.0
    )

    concurrent "${args[@]}"
}

my_sleep() {
    local seconds=${1}
    local code=${2:-0}
    echo "Yay! Sleeping for ${seconds} second(s)!"
    sleep "${seconds}"
    if [ "${code}" -ne 0 ]; then
        echo "Oh no! Terrible failure!" 1>&2
    fi
    return "${code}"
}

#nesting_success
#echo OK
#exit

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
#test_borg
summary

echo "DIST_PATH=$DIST_PATH"
