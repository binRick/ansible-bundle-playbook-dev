export _MODULE_REPOS="
    git+https://github.com/binRick/python3-parse-nagios-status-dat \
"
export MODULE_REPOS="
"

BUILD_SCRIPT_REPLACEMENTS="_ansible.py|ansible.py _glances.py|glances.py"

export BUILD_SCRIPTS="\
    _glances.py \
"
export _BUILD_SCRIPTS="\
    test.py \
    _ansible.py \
    ansible-playbook.py \
    ${_BORG_BUILD_NAME}.py \
    ansible-config.py \
    speedtest-cli.py \
    ansible-vault.py \
    paramiko_test.py \
    nagios_parser_test.py \
    tmuxp.py \
    tcshow.py \
    j2.py \
"

export BUILD_BORG=0
export ANSIBLE_VERSION=2.8.8
export BUILD_ANSIBLE=0

TEMPLATING_MODULES="j2cli jinja2"
JSON_MODULES="simplejson jmespath json2yaml jsondiff kaptan"
NIFTY_MODULES="pyinotify backoff humanize PyInquirer sshtunnel"
TERMINAL_MODULES="blessings terminaltables"
SYSTEM_PERFORMANCE_MODULES="glances"
CRYPTO_MODULES="python-jose[cryptography]"
SUBPROCESS_MODULES="bash.py"
NETWORK_MODULES="netaddr urllib3 websocket-client python-socketio"
PROCESS_MODULES="psutil cpython-prctl setproctitle"
COMPILER_MODULES="Cython"
ANSIBLE_MODULES="configparser paramiko $JSON_MODULES $NETWORK_MODULES $TERMINAL_MODULES"

BASE_MODS="loguru pyyaml pyaml requests $ANSIBLE_MODULES $JSON_MODULES $NETWORK_MODULES $COMPILER_MODULES"
ADDTL_MODS="speedtest-cli docopt python-jose pycryptodome halo $TEMPLATING_MODULES $CRYPTO_MODULES $SYSTEM_PERFORMANCE_MODULES"
OPTIONAL_MODULES="tcconfig pexpect libtmux tmuxp tcconfig $NIFTY_MODULES"

export _MODULES="\
    $OPTIONAL_MODULES \
    $ADDTL_MODS \
    $BASE_MODS \
"
MODULES="\
    glances
"


export MODULES="$(echo $MODULES|tr ' ' '\n'|sort -u|grep -v '^$' | tr '\n' ' ')"
