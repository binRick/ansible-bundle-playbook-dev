[[ "$BUILD_MODE" == "" ]] && export BUILD_MODE=default
[[ "$ANSIBLE_MODE" == "" ]] && export ANSIBLE_MODE=0
[[ "$DEBUG_VARS" == "" ]] && export DEBUG_VARS=0

if [[ "$DEBUG_VARS" == "1" ]]; then
    >&2 echo pre_MODULES=$MODULES
    >&2 echo pre_BUILD_SCRIPTS=$BUILD_SCRIPTS
    >&2 echo BUILD_MODE=$BUILD_MODE
fi

export MODULE_REPOS="\
"
export __MODULE_REPOS="\
    git+https://github.com/binRick/python3-parse-nagios-status-dat \
"

BUILD_SCRIPT_REPLACEMENTS="\
    _ansible.py|ansible.py \
    _pproxy.py|pproxy.py \
    __borg.py|borg.py \
"

[[ "$BUILD_SCRIPTS" == "" ]] && export BUILD_SCRIPTS="\
    _pproxy.py \
    test.py \
"
export _BUILD_SCRIPTS="\
    _ansible.py \
    ansible-playbook.py \
    ansible-config.py \
    speedtest-cli.py \
    ansible-vault.py \
    paramiko_test.py \
    ${_BORG_BUILD_NAME}.py \
    tmuxp.py \
    tcshow.py \
    j2.py \
"

[[ "$BUILD_BORG" == "" ]] && export BUILD_BORG=0
[[ "$ANSIBLE_VERSION" == "" ]] && export ANSIBLE_VERSION=2.8.9
[[ "$BUILD_ANSIBLE" == "" ]] && export BUILD_ANSIBLE=0

TEMPLATING_MODULES="j2cli jinja2"
JSON_MODULES="simplejson jmespath json2yaml jsondiff kaptan"
NIFTY_MODULES="pyinotify backoff humanize PyInquirer sshtunnel"
TERMINAL_MODULES="blessings terminaltables"
SYSTEM_PERFORMANCE_MODULES=""
CRYPTO_MODULES="python-jose[cryptography]"
SUBPROCESS_MODULES="bash.py"
DATA_MODULES="msgpack"
NETWORK_MODULES="netaddr urllib3 websocket-client python-socketio"
PROXY_MODULES="pproxy"
PROCESS_MODULES="psutil cpython-prctl setproctitle"
COMPILER_MODULES="Cython"
WHMCS_MODULES="whmcspy"
WEBSOCKET_MODULES="SimpleWebSocketServer"
ANSIBLE_MODULES="configparser paramiko $JSON_MODULES $NETWORK_MODULES $TERMINAL_MODULES $DATA_MODULES"

BASE_MODS="loguru pyyaml pyaml requests $ANSIBLE_MODULES $JSON_MODULES $NETWORK_MODULES $COMPILER_MODULES $PROXY_MODULES"
ADDTL_MODS="speedtest-cli docopt python-jose pycryptodome halo $TEMPLATING_MODULES $CRYPTO_MODULES $SYSTEM_PERFORMANCE_MODULES $WHMCS_MODULES $WEBSOCKET_MODULES"
OPTIONAL_MODULES="tcconfig pexpect libtmux tmuxp tcconfig $NIFTY_MODULES"


ALL_MODULES="$BASE_MODS $ADDTL_MODS $OPTIONAL_MODULES"

export _MODULES="\
    $BASE_MODS \
"
[[ "$MODULES" == "" ]] && export MODULES="\
    $ADDTL_MODS \
    $BASE_MODS \
"



if [[ "$BUILD_MODE" == "ANSIBLE+BORGS+TOOLS" ]]; then
    export BUILD_SCRIPTS="_ansible ansible-playbook ansible-vault ansible-config ansible-vault ansible-pull ansible-console ansible-doc \
    _pproxy.py \
    paramiko_test.py \
    speedtest-cli.py \
    __borg.py \
    ${_BORG_BUILD_NAME}.py \
"
#    nagios_parser_test.py \

    export BUILD_ANSIBLE=1
    export BUILD_BORG=0 && echo "$BUILD_SCRIPTS"|grep -iq borg && export BUILD_BORG=1
    export MODULES="$ALL_MODULES"
elif [[ "$ANSIBLE_MODE" == "1" ]]; then
    export BUILD_SCRIPTS="_ansible ansible-playbook ansible-vault ansible-config ansible-vault ansible-pull ansible-console ansible-doc"
    export BUILD_ANSIBLE=1
    export BUILD_BORG=0
    export MODULES="paramiko configparser simplejson jmespath json2yaml jsondiff kaptan psutil setproctitle blessings terminaltables jinja2 jmespath netaddr urllib3"
fi

export MODULES="$(echo $MODULES|tr ' ' '\n'|sort -u|grep -v '^$' | tr '\n' ' ')"
export BUILD_SCRIPTS="$(echo $BUILD_SCRIPTS|tr ' ' '\n'|sort -u|grep -v '^$' | tr '\n' ' ')"

if [[ "$DEBUG_VARS" == "1" ]]; then
    >&2 echo post_MODULES=$MODULES
    >&2 echo post_BUILD_SCRIPTS=$BUILD_SCRIPTS
fi
