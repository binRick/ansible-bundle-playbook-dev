export MODULE_REPOS="
"
export _MODULE_REPOS="
    git+https://github.com/binRick/python3-parse-nagios-status-dat \
"

export BUILD_SCRIPTS="\
    ansible-playbook.py \
"
export _BUILD_SCRIPTS="\
    paramiko_test.py \
    ansible-config.py \
    ansible-vault.py \
    ${_BORG_BUILD_NAME}.py \
    nagios_parser_test.py \
    test-hyphen.py \
    test1.py \
    tmuxp.py \
    tcshow.py \
"

BASE_MODS="psutil loguru json2yaml setproctitle pyyaml pyaml requests json2yaml"
ANSIBLE_MODULES="ansible simplejson terminaltables netaddr configparser jmespath urllib3"
ADDTL_MODS="speedtest-cli docopt python-jose pycryptodome paramiko psutil"

export _MODULES="\
    pexpect \
    tcconfig \
    libtmux \
    tmuxp \
    tcconfig \
    halo \
    $ADDTL_MODS \
    $ANSIBLE_MODULES \
    $BASE_MODS \
"
export MODULES="\
    $ANSIBLE_MODULES
"
