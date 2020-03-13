

export DISABLE_AUTO_UPDATE=true


#   """ Script Mangling """
export _REMOVE_SHEBANG_LINE_FROM_ANSIBLE_CLI_SCRIPTS=1

#   """ Ansible """
export _OVERWRITE_MANAGER_FILE=0
export _OVERWRITE_ANSIBLE_CLI_SCRIPTS=0
export _ADD_DATA_ANSIBLE_PATH=ansible
export _EXCLUDE_ANSIBLE_MODULES=0

#   """ File Caching """
SAVE_MODULE_PATH=/tmp/SAVED_MODULES

#   """ Borg Build """
[[ "$PLAINTEXT_PASSPHRASE" == "" ]] && PLAINTEXT_PASSPHRASE="12345678"
[[ "$ENCRYPTED_PASSPHRASE" == "" ]] && ENCRYPTED_PASSPHRASE="yEGDBcJ2lKcFdhhay2kJDg=="

#   """ Cython Compiler :: Used to compile bin/* Python Wrapper Scripts, not the build scripts """
export CYTHON_COMPILE_LIBS="-lpthread -lm -lutil -ldl"
export CYTHON_COMPILE_PYTHON_VERSION=2

if [[ "$CYTHON_COMPILE_PYTHON_VERSION" == "3" ]]; then
    #   """ Python 3 """
    export CYTHON_PYTHON_COMPILE_LIBRARY_PATH=/usr/include/python3.6m
    export CYTHON_PYTHON_LIBRARY=python3.6m
elif [[ "$CYTHON_COMPILE_PYTHON_VERSION" == "2" ]]; then
    #   """ Python 2 """
    export CYTHON_PYTHON_COMPILE_LIBRARY_PATH=/usr/include/python2.7
    export CYTHON_PYTHON_LIBRARY=python2.7
fi

#   """ Borg Cache """
export CHECK_BORG=0
export PRUNE_BORG=0
export SAVE_BUILD_TO_BORG=1
export BORG_KEEP_WITHIN_DAYS=30
export _BORG_URL="https://github.com/borgbackup/borg/releases/download/1.1.10/borg-linux64"
export BORG_ARGS="--lock-wait 20"
export BORG_REPO=~/.bundler.borg
export BORG_PASSPHRASE=456729372362
[[ "$_BORG_BUILD_NAME" == "" ]] && export _BORG_BUILD_NAME=MYBORG

#   """ Directory Management """
#export _DATA_PREFIX=data/ansible
export _DATA_PREFIX=ansible
export _DIR_PATH_PREFIX=ansible-playbook
export _RELOCATE_PATH=1
#export _RELOCATE_PATH_PREFIX=.lib/
export _RELOCATE_PATH_PREFIX=.lib/
export _RELOCATE_MODULES='j2cli[yaml] json2yaml cython'

#   """ Exec Wrapper """
export _RELOCATE_BIN_WRAPPER_SCRIPT_TEMPLATE_FILE=bin-script.j2.py
export _RELOCATE_BIN_WRAPPER_SCRIPT_VARS_FILE=bin-script-vars.yaml
