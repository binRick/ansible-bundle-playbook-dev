




#   """ Script Mangling """
export _REMOVE_SHEBANG_LINE_FROM_ANSIBLE_CLI_SCRIPTS=1

#   """ Ansible """
ANSIBLE_VERSION=2.8.8
export _OVERWRITE_MANAGER_FILE=1
export _OVERWRITE_ANSIBLE_CLI_SCRIPTS=0
export BUILD_ANSIBLE=1
export _ADD_DATA_ANSIBLE_PATH=ansible
export _EXCLUDE_ANSIBLE_MODULES=0

#   """ File Caching """
SAVE_MODULE_PATH=/tmp/SAVED_MODULES

#   """ Borg Build """
export BUILD_BORG=1
[[ "$PLAINTEXT_PASSPHRASE" == "" ]] && PLAINTEXT_PASSPHRASE="12345678"
[[ "$ENCRYPTED_PASSPHRASE" == "" ]] && ENCRYPTED_PASSPHRASE="yEGDBcJ2lKcFdhhay2kJDg=="

#   """ Borg Cache """
export SAVE_BUILD_TO_BORG=0
export BORG_KEEP_WITHIN_DAYS=30
export _BORG_URL="https://github.com/borgbackup/borg/releases/download/1.1.10/borg-linux64"
export BORG_ARGS="--lock-wait 20"
export BORG_REPO=~/.bundler.borg
export BORG_PASSPHRASE=456729372362
[[ "$_BORG_BUILD_NAME" == "" ]] && export _BORG_BUILD_NAME=MYBORG

#   """ Directory Management """
export _DATA_PREFIX=data/ansible
export _DIR_PATH_PREFIX=ansible-playbook
export _RELOCATE_PATH=1
#export _RELOCATE_PATH_PREFIX=.lib/
export _RELOCATE_PATH_PREFIX=.lib/
export _RELOCATE_MODULES='j2cli[yaml] json2yaml cython'

#   """ Exec Wrapper """
export _RELOCATE_BIN_WRAPPER_SCRIPT_TEMPLATE_FILE=bin-script.j2.py
export _RELOCATE_BIN_WRAPPER_SCRIPT_VARS_FILE=bin-script-vars.yaml
