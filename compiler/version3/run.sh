#!/bin/bash
set -e
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
export ORIG_DIR="$(pwd)"
source setup.sh >/dev/null 2>/dev/null
export STARTED_TS=$(date +%s)
BUILD_MODE=serial
[[ ! -d ".venv-1" ]] && setup_venv

concurrent_build() {
    local args=(
        - "Cleanup Past Compilations"       cleanup_compileds
        --and-then \
        - "Setup Virtual Environment"       setup_venv
        --and-then \
        - "Fix Importlib version.txt bug" ./fix_importlib_version.txt.sh
        --and-then \
        - "Install Borg"       install_borg
        --and-then \
        - "Validate Borg"       ensure_borg
        --and-then \
        - "Load Variables"       load_vars
        --and-then \
        - "Run Build"                   run_build
        --and-then \
        - "Normalize Dist Path"         normalize_dist_path
        --and-then \
        - "Test Dist Path"              test_dist-path
        --and-then \
        - "Setup Virtual Environment"   echo setup_venv
        --and-then \
        - "Relocate Dist Path"          relocate_path
        --and-then \
        - "Print Summary"               summary
    )
    local _args=(
        - "Save Modules to Borg"       save_build_to_borg "$DIST_PATH"
        - "Test Borg"       test_borg
        - "Deactivate Virtual Environment"       deactivate
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
    #concurrent "${__args[@]}"
}

basic_build(){
#    set -e
    cleanup_compileds
    setup_venv
    ansi --yellow --underline --bg-black "Fix Importlib version.txt bug" && ./fix_importlib_version.txt.sh
    install_borg
    ensure_borg
    command -v deactivate >/dev/null 2>&1 && deactivate
    load_vars
    run_build
    normalize_dist_path
    test_dist_path
    setup_venv
    relocate_path
    save_build_to_borg "$DIST_PATH"
    #test_borg
    summary
}






if [[ "$BUILD_MODE" == "concurrent" ]]; then
    concurrent_build
else
    basic_build
fi


echo OK
echo "DIST_PATH=$DIST_PATH"
exit






