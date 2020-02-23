#!/bin/bash
set -e
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
ANSIBLE_VERSION=2.8.8
#if [[ -d .venv-1 ]]; then rm -rf .venv-1; fi

python3 -m venv .venv-1
source .venv-1/bin/activate

set +e
#pip -q uninstall -y ansible >/dev/null 2>&1
set -e
pip -q install ansible==$ANSIBLE_VERSION

for x in playbook config; do
    [[ -f ansible-${x}.py ]] && unlink ansible-${x}.py
    [[ -f ansible-${x} ]] && unlink ansible-${x}
    cp $(which ansible-${x}) ansible-${x}.py
    head -n 1 ansible-${x}.py | grep -q '^#!' && sed -i 1d ansible-${x}.py
done


deactivate

export MODULE_REPOS="
    git+https://github.com/binRick/python3-parse-nagios-status-dat \
"
export _MODULE_REPOS="
"

export BUILD_SCRIPTS="\
    ansible-playbook.py \
    ansible-config.py \
" 
export _BUILD_SCRIPTS="\
    ansible-vault.py \
    paramiko_test.py \
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
" 
export MODULES="\
    $BASE_MODS \
    $ADDTL_MODS \
    requests \
    pyaml \
    ansible \
    setproctitle \
    configparser \
    json2yaml \
    paramiko \
    psutil \
" 

[[ -f .stdout ]] && unlink .stdout

./build.sh 2>&1 | tee .stdout
exit_code=$?

DIST_PATH="$(pwd)/$(grep '^.COMBINED-' .stdout|tail -n1)"
mv $DIST_PATH ${DIST_PATH}.t
mkdir $DIST_PATH
mv ${DIST_PATH}.t $DIST_PATH/ansible-playbook


echo "DIST_PATH=$DIST_PATH"
exit $exit_code


