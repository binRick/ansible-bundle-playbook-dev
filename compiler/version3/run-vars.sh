export MODULE_REPOS="
"
export _MODULE_REPOS="
    git+https://github.com/binRick/python3-parse-nagios-status-dat \
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

BASE_MODS="psutil loguru json2yaml setproctitle pyyaml pyaml requests json2yaml psutil paramiko"
ANSIBLE_MODULES="ansible simplejson terminaltables netaddr configparser jmespath urllib3"
ADDTL_MODS="speedtest-cli docopt python-jose pycryptodome"

export _MODULES="\
    pexpect \
    tcconfig \
    libtmux \
    halo \
    tmuxp \
    tcconfig \
    $ANSIBLE_MODULES \
    $ADDTL_MODS \
"
export MODULES="\
    $BASE_MODS \
"
