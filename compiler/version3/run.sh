#!/bin/bash
set -e
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
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
pip install -r _borg/requirements.d/development.txt
pip install -e _borg
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
    ${_BORG_BUILD_NAME}.py \
    ansible-playbook.py \
    ansible-config.py \
    ansible-vault.py \
" 
export _BUILD_SCRIPTS="\
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

mv ../files/ansible.cfg $DIST_PATH/ansible-playbook/.


echo "DIST_PATH=$DIST_PATH"
exit $exit_code


