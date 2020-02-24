#!/bin/bash
set -e
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
export ORIG_DIR="$(pwd)"
source ../.ansi
ANSIBLE_VERSION=2.8.8
[[ "$_BORG_BUILD_NAME" == "" ]] && export _BORG_BUILD_NAME=MYBORG
#if [[ -d .venv-1 ]]; then rm -rf .venv-1; fi

python3 -m venv .venv-1
source .venv-1/bin/activate
pip -q install pip --upgrade
set +e
#pip -q uninstall -y ansible >/dev/null 2>&1
set -e
pip -q install ansible==$ANSIBLE_VERSION

[[ -f ansible-playbook.py ]] && unlink ansible-playbook.py
[[ -f ansible-config.py ]] && unlink ansible-config.py
cp $(which ansible-playbook) ansible-playbook.py
cp $(which ansible-config) ansible-config.py


for x in playbook config vault; do
  [[ -f ansible-${x}.py ]] && unlink ansible-${x}.py
  [[ -f ansible-${x} ]] && unlink ansible-${x}
  cp $(which ansible-${x}) ansible-${x}.py
  head -n 1 ansible-${x}.py | grep -q '^#!' && sed -i 1d ansible-${x}.py
done


[[ -d _borg ]] || git clone https://github.com/binRick/borg _borg
(cd _borg && git pull)
pip -q install python-jose pycryptodome
pip install -q -r _borg/requirements.d/development.txt
pip install -q -e _borg
cp -f _borg/src/borg/__main__.py BORG.py
python BORG.py --help >/dev/null 2>&1
>&2 ansi --green Pre compile BORG.py validated OK

deactivate

export MODULE_REPOS="
    git+https://github.com/binRick/python3-parse-nagios-status-dat \
"
export _MODULE_REPOS="
"

export BUILD_SCRIPTS="\
    paramiko_test.py \
" 
export _BUILD_SCRIPTS="\
    ${_BORG_BUILD_NAME}.py \
    ansible-playbook.py \
    ansible-config.py \
    ansible-vault.py \
    nagios_parser_test.py \
    test-hyphen.py \
    test.py \
    test1.py \
    tmuxp.py \
    tcshow.py \
" 

BASE_MODS="simplejson psutil loguru json2yaml setproctitle pyyaml pyaml"
ADDTL_MODS="terminaltables speedtest-cli netaddr configparser urllib3 jmespath paramiko docopt"

export _MODULES="\
    pexpect \
    tcconfig \
    libtmux \
    halo \
    tmuxp \
    tcconfig \
    ansible \
" 
export MODULES="\
    $BASE_MODS \
    $ADDTL_MODS \
    requests \
    pyaml \
    setproctitle \
    configparser \
    json2yaml \
    paramiko \
    psutil \
" 

SAVE_MODULE_PATH=/tmp/SAVED_MODULES
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


save_modules

exit 123



[[ -f .stdout ]] && unlink .stdout
set -e
./build.sh 2>&1 | tee .stdout
exit_code=$?
if [[ "$exit_code" != "0" ]]; then
        ansi --red "     build.sh failed with exit code $exit_Code"
        exit $exit_code
fi
DIST_PATH="$(pwd)/$(grep '^.COMBINED-' .stdout|tail -n1)"
if [[ ! -d "$DIST_PATH" ]]; then
        ansi --red "     invalid DIST_PATH detected... \"$DIST_PATH\" is not a directory."
        exit 101
fi

mv $DIST_PATH ${DIST_PATH}.t
mkdir $DIST_PATH
mv ${DIST_PATH}.t $DIST_PATH/ansible-playbook

#mv $ORIG_DIR/ansible.cfg $DIST_PATH/ansible-playbook/.
echo $ANSIBLE_CFG_B64|base64 -d > $DIST_PATH/ansible-playbook/ansible.cfg



echo "DIST_PATH=$DIST_PATH"

save_modules


exit $exit_code
