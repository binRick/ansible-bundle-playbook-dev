[[ "$SCRIPTS_BUILD_MODE" == "" ]] && export BUILD_MODE=default
[[ "$ANSIBLE_MODE" == "" ]] && export ANSIBLE_MODE=0
[[ "$DEBUG_VARS" == "" ]] && export DEBUG_VARS=0

if [[ "$DEBUG_VARS" == "1" ]]; then
    >&2 echo pre_MODULES=$MODULES
    >&2 echo pre_BUILD_SCRIPTS=$BUILD_SCRIPTS
    >&2 echo SCRIPTS_BUILD_MODE=$SCRIPTS_BUILD_MODE
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
    __ara-manage.py|ara-manage.py \
    __tester.py|tester.py \
"

#    netstat.py \
[[ "$BUILD_SCRIPTS" == "" ]] && export BUILD_SCRIPTS="\
    __tester.py \
"
#    pstree.py \
#    remote_execution_monitor.py \
export _BUILD_SCRIPTS="\
    __test_tmux.py
    speedtest-cli.py \
    ansible-playbook.py \
    _pproxy.py \
    test.py \
    _ansible.py \
    remote_execution_monitor.py \
    ansible-config.py \
    ansible-vault.py \
    paramiko_test.py \
    ${_BORG_BUILD_NAME}.py \
    tmuxp.py \
    tcshow.py \
    j2.py \
"

[[ "$BUILD_BORG" == "" ]] && export BUILD_BORG=0
[[ "$ANSIBLE_VERSION" == "" ]] && export ANSIBLE_VERSION=2.8.13
[[ "$BUILD_ANSIBLE" == "" ]] && export BUILD_ANSIBLE=0

REQUIRED_COMPILER_MODULES="Cython pyinstaller"
BORG_MODULES=""
TMUX_MODULES="libtmux"
TEMPLATING_MODULES="j2cli jinja2"
JSON_MODULES="json2yaml jsondiff kaptan"
NIFTY_MODULES="pyinotify backoff humanize PyInquirer sshtunnel"
TERMINAL_MODULES="blessings paramiko_expect"
SERVICE_MODULES="sdnotify"
SYSTEM_PERFORMANCE_MODULES=""
CRYPTO_MODULES="python-jose[cryptography]"
SUBPROCESS_MODULES="bash.py backoff"
DATA_MODULES="msgpack"
NETWORK_MODULES="urllib3 websocket-client python-socketio tcconfig"
PROXY_MODULES="pproxy"
PROCESS_MODULES="psutil cpython-prctl setproctitle"
COMPILER_MODULES="$REQUIRED_COMPILER_MODULES"
WHMCS_MODULES="whmcspy"
WEBSOCKET_MODULES="SimpleWebSocketServer"
#ARA_SERVER_MODULES="ara[server]==1.4.0"
ANSIBLE_MODULES="ara simplejson jmespath terminaltables netaddr configparser paramiko $JSON_MODULES $NETWORK_MODULES $TERMINAL_MODULES $DATA_MODULES $COMPILER_MODULES"
#ARA_MODULES="Django==2.1.* ara[server]"

BASE_MODS="psutil paramiko speedtest-cli $BORG_MODULES"
TMUX_MODS="libtmux tmuxp"
TERMINAL_MODS="pexpect"
ADDTL_MODS="docopt python-jose pycryptodome halo $TEMPLATING_MODULES $CRYPTO_MODULES $SYSTEM_PERFORMANCE_MODULES $WHMCS_MODULES $WEBSOCKET_MODULES \
    loguru pyyaml pyaml requests $ANSIBLE_MODULES $JSON_MODULES $NETWORK_MODULES $PROXY_MODULES"
OPTIONAL_MODULES="$NIFTY_MODULES $TMUX_MODULES $TMUX_MODS $TERMINAL_MODS"


ALL_MODULES="$BASE_MODS $ADDTL_MODS $OPTIONAL_MODULES"

export _MODULES="\
    $BASE_MODS \
"
[[ "$MODULES" == "" ]] && export MODULES="\
    $BASE_MODS \
    $TERMINAL_MODULES \
    $TMUX_MODULES \
"



>&2 ansi --green "[run-vars.sh]  Executing build using mode \"$SCRIPTS_BUILD_MODE\""

############################################################
############################################################
if [[ "$SCRIPTS_BUILD_MODE" == "ANSIBLE+BORGS+TOOLS" ]]; then
############################################################
#    netstat.py \
    export __BUILD_SCRIPTS="\
    __ara-manage.py \
      ansible-pull \
      ansible-console \
      ansible-doc \
    remote_execution_monitor.py \
    pstree.py \
    paramiko_test.py \
    speedtest-cli.py \
    _pproxy.py \
    "
    export BUILD_SCRIPTS="\
    _ansible \
    ${_BORG_BUILD_NAME}.py \
    __borg.py \
      ansible-config \
      ansible-playbook \
      ansible-vault \
"
    echo "$BUILD_SCRIPTS"|grep -iq borg && export BUILD_BORG=1
    echo "$BUILD_SCRIPTS"|grep -iq ansible && export BUILD_ANSIBLE=1
    export MODULES="$BASE_MODS $ADDTL_MODS"
    export SPECIFIED_MODULE_NAMES="" #'ara[server]' 'Django==2.1.*' pytz"

    export MODULES="$ALL_MODULES"
    export SPECIFIED_MODULE_NAMES=""

############################################################
############################################################
elif [[ "$SCRIPTS_BUILD_MODE" == "ARA" ]]; then
    export BUILD_SCRIPTS="__ara-manage.py"
    export BUILD_ANSIBLE=0
    export BUILD_BORG=0
    export MODULES="Django==2.1.* ara[server] toml pytz"
elif [[ "$SCRIPTS_BUILD_MODE" == "ANSIBLE-PLAYBOOK" ]]; then
############################################################
    export BUILD_SCRIPTS="ansible-playbook"
    export BUILD_ANSIBLE=1
    export BUILD_BORG=0
    export MODULES="paramiko configparser simplejson jmespath json2yaml jsondiff kaptan psutil setproctitle blessings terminaltables jinja2 jmespath netaddr urllib3"

>&2 echo -e "MODULE_REPOS=$MODULE_REPOS"
#exit 99

############################################################
############################################################
elif [[ "$ANSIBLE_MODE" == "1" ]]; then
############################################################
    export BUILD_SCRIPTS="_ansible ansible-playbook ansible-vault ansible-config ansible-vault ansible-pull ansible-console ansible-doc"
    export BUILD_ANSIBLE=1
    export BUILD_BORG=0
    export MODULES="paramiko configparser simplejson jmespath json2yaml jsondiff kaptan psutil setproctitle blessings terminaltables jinja2 jmespath netaddr urllib3"
fi

export MODULES="$(echo $MODULES $REQUIRED_COMPILER_MODULES|tr ' ' '\n'|sort -u|grep -v '^$' | tr '\n' ' ')"
export BUILD_SCRIPTS="$(echo $BUILD_SCRIPTS|tr ' ' '\n'|sort -u|grep -v '^$' | tr '\n' ' ')"

if [[ "$DEBUG_VARS" == "1" ]]; then
    >&2 echo post_MODULES=$MODULES
    >&2 echo post_BUILD_SCRIPTS=$BUILD_SCRIPTS
fi
