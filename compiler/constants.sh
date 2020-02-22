export DEBUG_MODE=1

ADDITIONAL_COMPILED_MODULES_REPLACEMENTS="pyyaml|yaml python-jose|jose python_jose|jose pyopenssl|OpenSSL mysql-connector-python|mysql mysql_connector_python|mysql linode-cli|linodecli linode_cli|linodecli speedtest-cli|speedtest websocket-client|websocket"


_combined_stdout=.combined.stdout
_combined_stderr=.combined.stderr
combined_stdout=.combined-compile.stdout
combined_stderr=.combined-compile.stderr
combined_cmd=.combined-cmd.sh
spec_combined_cmd=.combined-spec-cmd.sh
spec_combined_stdout_mkspec=.combined-mkspec.stdout
spec_combined_stderr_mkspec=.combined-mkspec.stderr

VENV_DIR=".venv-1"
NUKE_VENV=0
MANGLE_SCRIPT="./mangleSpec.sh"


#_ADD_DATAS="\$(echo \$_ADD_DATAS|tr ' ' '\n'|grep -v '^$'|sort -u |tr '\n' ' ')"

EXCLUDED_PYARMOR_MODULES="ansible.modules.database.mongodb ansible.modules.database.mongodb.mongodb_parameter ansible.modules.database.mongodb.mongodb_replicaset ansible.modules.database.mongodb.mongodb_shard ansible.modules.database.mongodb.mongodb_user \
        ansible.plugins.cache.mongodb \
        ansible.plugins.lookup.mongodb \
        ansible.plugins.filter.k8s \
        ansible.plugins.cache.jsonfile ansible.plugins.cache.memcached ansible.plugins.cache.mongodb ansible.plugins.cache.pickle ansible.plugins.cache.redis ansible.plugins.cache.yaml \
        ansible.plugins.callback.jabber ansible.plugins.callback.grafana_annotations ansible.plugins.callback.aws_resource_actions \
"
EXCLUDED_ADDITIONAL_MODULES="watchdog.utils.win32stat ansible.plugins.callback.detailed $EXCLUDED_PYARMOR_MODULES"

EXCLUDED_ANSIBLE_MODULES="$EXCLUDED_ADDITIONAL_MODULES ansible.modules.network ansible.modules.cloud ansible.modules.remote_management ansible.modules.storage ansible.modules.web_infrastructure ansible.modules.windows ansible.module_utils.network ansible.plugins.doc_fragments ansible.plugins.terminal ansible.modules.net_tools ansible.modules.monitoring.zabbix ansible.modules.messaging ansible.modules.identity ansible.modules.database.postgresql ansible.modules.database.proxysql ansible.modules.database.vertica ansible.modules.database.influxdb ansible.modules.clustering ansible.modules.source_control.bitbucket ansible.module_utils.aws ansible.plugins.cliconf $(cat ../EXCLUDED_ANSIBLE_MODULES.txt|sort -u|tr '\n' ' ')"


ADDITIONAL_ANSIBLE_CALLLBACK_MODULES="https://raw.githubusercontent.com/binRick/ansible-callback-concise/master/callback_plugins/codekipple_concise.py https://raw.githubusercontent.com/binRick/ansible-beautiful-output/master/callback_plugins/beautiful_output.py https://raw.githubusercontent.com/binRick/ansible-json-audit-log/master/callback/json_audit.py"
#ADDITIONAL_ANSIBLE_CALLLBACK_MODULES=""

ADDITIONAL_ANSIBLE_LIBRARY_MODULES="https://raw.githubusercontent.com/binRick/ansible-mysql-query/master/library/mysql_query.py https://raw.githubusercontent.com/ageis/ansible-module-ping/master/modules/icmp_ping.py https://raw.githubusercontent.com/cleargray/git_commit/master/git_commit.py https://raw.githubusercontent.com/binRick/mysql_database_query/master/mysql_database_query.py"
#ADDITIONAL_ANSIBLE_LIBRARY_MODULES=""
