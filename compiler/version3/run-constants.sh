ANSIBLE_VERSION=2.8.8

SAVE_MODULE_PATH=/tmp/SAVED_MODULES
export BORG_ARGS="--lock-wait 20"
export BORG_REPO=~/.bundler.borg
export BORG_PASSPHRASE=456729372362
[[ "$_BORG_BUILD_NAME" == "" ]] && export _BORG_BUILD_NAME=MYBORG

export BUILD_BORG=0
export BUILD_ANSIBLE=0
export BORG_KEEP_WITHIN_DAYS=30

