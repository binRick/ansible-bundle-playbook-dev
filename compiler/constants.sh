export DEBUG_MODE=1

ADDITIONAL_COMPILED_MODULES_REPLACEMENTS="pyyaml|yaml python-jose|jose python_jose|jose pyopenssl|OpenSSL mysql-connector-python|mysql mysql_connector_python|mysql linode-cli|linodecli linode_cli|linodecli speedtest-cli|speedtest websocket-client|websocket"


combined_stdout=.combined-compile.stdout
combined_stderr=.combined-compile.stderr
combined_cmd=.combined-cmd.sh

VENV_DIR=".venv-1"
NUKE_VENV=0
MANGLE_SCRIPT="./mangleSpec.sh"


_ADD_DATAS="--add-data $VIRTUAL_ENV/lib/python3.6/site-packages/ansible/config/base.yml:ansible/config \
                    --add-data $VIRTUAL_ENV/lib/python3.6/site-packages/ansible/config/module_defaults.yml:ansible/config \
                    --add-data $VIRTUAL_ENV/lib/python3.6/site-packages/ansible/utils/shlex.py:ansible/utils \
                    --add-data $VIRTUAL_ENV/lib/python3.6/site-packages/ansible/plugins/cache:ansible/plugins/cache \
                    --add-data $VIRTUAL_ENV/lib/python3.6/site-packages/ansible/module_utils:ansible/module_utils \
                    --add-data $VIRTUAL_ENV/lib/python3.6/site-packages/ansible/plugins/inventory:ansible/plugins/inventory \
                    --add-data $VIRTUAL_ENV/lib/python3.6/site-packages/ansible/plugins:ansible/plugins \
                    --add-data $VIRTUAL_ENV/lib/python3.6/site-packages/ansible/modules:ansible/modules \
                    --add-data $VIRTUAL_ENV/lib/python3.6/site-packages/ansible/executor/discovery/python_target.py:ansible/executor/discovery \
"
#_ADD_DATAS="\$(echo \$_ADD_DATAS|tr ' ' '\n'|grep -v '^$'|sort -u |tr '\n' ' ')"
