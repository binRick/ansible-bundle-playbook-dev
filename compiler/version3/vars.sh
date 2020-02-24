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

BASE_MODS="simplejson psutil loguru json2yaml setproctitle pyyaml pyaml"
ADDTL_MODS="terminaltables speedtest-cli netaddr configparser urllib3 jmespath paramiko docopt python-jose pycryptodome"

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
