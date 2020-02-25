ANSIBLE_VERSION=2.8.8

SAVE_MODULE_PATH=/tmp/SAVED_MODULES
export BORG_ARGS="--lock-wait 20"
export BORG_REPO=~/.bundler.borg
export BORG_PASSPHRASE=456729372362
[[ "$_BORG_BUILD_NAME" == "" ]] && export _BORG_BUILD_NAME=MYBORG


_BORG_URL="https://github.com/borgbackup/borg/releases/download/1.1.10/borg-linux64"

export _DATA_PREFIX="ansible"
export BUILD_BORG=0
export _OVERWRITE_MANAGER_FILE=0
export _RELOCATE_ANSIBLE=0
export BUILD_ANSIBLE=1
export BORG_KEEP_WITHIN_DAYS=30
export _ADD_DATA_ANSIBLE_PATH=ansible
export _EXCLUDE_ANSIBLE_MODULES=0


