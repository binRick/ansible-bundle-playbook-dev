export MODULE_REPOS="
    git+https://github.com/binRick/python3-parse-nagios-status-dat \
"
export _MODULE_REPOS="
"

BUILD_SCRIPT_REPLACEMENTS="_ansible.py|ansible.py"
_BUILD_SCRIPT_REPLACEMENTS=""

export BUILD_SCRIPTS="\
    _ansible.py \
    ansible-playbook.py \
"
export _BUILD_SCRIPTS="\
    test.py \
    ansible-config.py \
    ansible-vault.py \
    paramiko_test.py \
    j2.py \
    ${_BORG_BUILD_NAME}.py \
    nagios_parser_test.py \
    test-hyphen.py \
    tmuxp.py \
    tcshow.py \
"

REQUIRED_MODULES="python-prctl setproctitle Cython psutil"
ANSIBLE_MODULES="simplejson terminaltables netaddr configparser jmespath urllib3"
BASE_MODS="loguru json2yaml jinja2 pyyaml pyaml requests json2yaml"
ADDTL_MODS="speedtest-cli docopt python-jose pycryptodome paramiko"

export _MODULES="\
    pexpect \
    tcconfig \
    libtmux \
    tmuxp \
    tcconfig \
    halo \
    $BASE_MODS \
    $ADDTL_MODS \
"
export MODULES="\
    $REQUIRED_MODULES \
    $ANSIBLE_MODULES \
"

