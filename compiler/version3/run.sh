#!/bin/bash
set -e
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source /etc/.ansi


export ORIG_DIR="$(pwd)"
ANSIBLE_VERSION=2.8.8
SAVE_MODULE_PATH=/tmp/SAVED_MODULES
[[ "$_BORG_BUILD_NAME" == "" ]] && export _BORG_BUILD_NAME=MYBORG


source run-utils.sh

setup_venv
deactivate
load_vars

[[ ! -d $SAVE_MODULE_PATH ]] && mkdir -p $SAVE_MODULE_PATH

get_module_saved_path(){
    _MODULE=$1
    _MODULE_MD5=$(echo $_MODULE|md5sum | cut -d' ' -f1)
    echo "$SAVE_MODULE_PATH/$_MODULE_MD5"
}

save_modules(){
    for m in $BUILD_SCRIPTS; do
        save_path=$(get_module_saved_path $m)
        cp_cmd="cp $DIST_PATH/ansible-playbook/$m $save_path"
        >&2 ansi --yellow "      Saving Build Script $m to $save_path with cmd:$(echo -e "\n\n           \"$cp_cmd\"\n\n")"
        >&2 pwd
    done
}

[[ -f .stdout ]] && unlink .stdout
[[ -f .stderr ]] && unlink .stderr
[[ -f .exit_code ]] && unlink .exit_code
set -e
bash -x ./build.sh > .stdout 2> .stderr
exit_code=$?
echo $exit_code > .exit_code

if [[ "$exit_code" != "0" ]]; then
        ansi --red "     build.sh failed with exit code $exit_code"
        exit $exit_code
fi
DIST_PATH="$(pwd)/$(grep '^.COMBINED-' .stdout|tail -n1)"
if [[ "$DIST_PATH" != "" || ! -d "$DIST_PATH" ]]; then
    ansi --red "     invalid DIST_PATH detected... \"$DIST_PATH\" is not a directory."
	ansi --green "$(cat .stdout)"
	ansi --red "$(cat .stderr)"
        exit 101
fi

>&2 ansi --green Validated DIST_PATH $DIST_PATH

save_modules

mv $DIST_PATH ${DIST_PATH}.t
mkdir $DIST_PATH
mv ${DIST_PATH}.t $DIST_PATH/ansible-playbook

#mv $ORIG_DIR/ansible.cfg $DIST_PATH/ansible-playbook/.
echo $ANSIBLE_CFG_B64|base64 -d > $DIST_PATH/ansible-playbook/ansible.cfg



echo "DIST_PATH=$DIST_PATH"



exit $exit_code
