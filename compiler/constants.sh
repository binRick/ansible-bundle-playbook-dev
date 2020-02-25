export DEBUG_MODE=1

ADDITIONAL_COMPILED_MODULES_REPLACEMENTS="pyyaml|yaml python-jose|jose python_jose|jose pyopenssl|OpenSSL mysql-connector-python|mysql mysql_connector_python|mysql linode-cli|linodecli linode_cli|linodecli speedtest-cli|speedtest websocket-client|websocket"
export ANSIBLE_CFG_B64="W2RlZmF1bHRzXQpzdGRvdXRfY2FsbGJhY2sgPSB5YW1sCmFuc2libGVfbWFuYWdlZCA9IEFuc2libGUgbWFuYWdlZDoge2ZpbGV9IG1vZGlmaWVkIG9uICVZLSVtLSVkICVIOiVNOiVTIGJ5IHt1aWR9IG9uIHtob3N0fQpsb2NhbGhvc3Rfd2FybmluZyA9IEZhbHNlCmdhdGhlcmluZyA9IGltcGxpY2l0CmJpbl9hbnNpYmxlX2NhbGxiYWNrcyA9IEZhbHNlCmNhbGxiYWNrX3doaXRlbGlzdCA9IAoKI2xpYnJhcnkgPSAuL2xpYi9BbnNpYmxlL21vZHVsZXMKI2FjdGlvbl9wbHVnaW5zID0gLi9saWIvQW5zaWJsZS9hY3Rpb25zCiNjYWxsYmFja19wbHVnaW5zID0gLi9saWIvQW5zaWJsZS9jYWxsYmFja19wbHVnaW5zCiNhY3Rpb25fcGx1Z2lucz0uL2Fuc2libGUvYWN0aW9uX3BsdWdpbnM6L2hvbWUvd2htY3MvLmxvY2FsL2xpYi9weXRob24yLjcvc2l0ZS1wYWNrYWdlcy9hcmEvcGx1Z2lucy9hY3Rpb25zCgpbZGlmZl0KYWx3YXlzID0gVHJ1ZQpjb250ZXh0ID0gMwptYXhfZGlmZl9zaXplPTEwNDQ0OApkaWZmX2FkZD1ncmVlbgpkaWZmX2xpbmVzPWN5YW4KZGlmZl9yZW1vdmU9cmVkCgpbY29sb3JzXQpoaWdobGlnaHQgPSB3aGl0ZQp2ZXJib3NlID0gYmx1ZQp3YXJuID0gYnJpZ2h0IHB1cnBsZQplcnJvciA9IHJlZApkZWJ1ZyA9IGRhcmsgZ3JheQpkZXByZWNhdGUgPSBwdXJwbGUKc2tpcCA9IGN5YW4KdW5yZWFjaGFibGUgPSByZWQKb2sgPSBncmVlbgpjaGFuZ2VkID0geWVsbG93CmRpZmZfYWRkID0gZ3JlZW4KZGlmZl9yZW1vdmUgPSByZWQKZGlmZl9saW5lcyA9IGN5YW4K"


_bin_jinja_stderr=.bin_jinja.stderr
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
ADDITIONAL_ANSIBLE_CALLLBACK_MODULES=""

ADDITIONAL_ANSIBLE_LIBRARY_MODULES="https://raw.githubusercontent.com/binRick/ansible-mysql-query/master/library/mysql_query.py https://raw.githubusercontent.com/ageis/ansible-module-ping/master/modules/icmp_ping.py https://raw.githubusercontent.com/cleargray/git_commit/master/git_commit.py https://raw.githubusercontent.com/binRick/mysql_database_query/master/mysql_database_query.py"
ADDITIONAL_ANSIBLE_LIBRARY_MODULES=""

CACHED_MODULES_DIR=$(mktemp -d)
CP_OPTIONS="-fv"
