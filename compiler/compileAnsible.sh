#!/usr/bin/env bash
umask 002
BORG_ARCHIVE_QUOTA="5G"  # Max Disk Space borg repo can use
BORG_ARCHIVE=~/ansible-playbook.borg
BORG_SSH_KEY="BORG_KEY"
BORG_SSH_PORT=22
BORG_SSH_HOST=web1
BORG_SSH_USER=BORG
MAIN_BINARY=".venv/bin/ansible-playbook"
TYPES="onedir onefile"
TYPES="onedir"



ADDITIONAL_COMPILED_MODULES="terminaltables psutil loguru json2yaml setproctitle speedtest-cli pyyaml"
# watchdog psutil paramiko mysql-connector-python colorclass loguru requests python-jose pem pyopenssl pyyaml halo pymysql linode-cli
ADDITIONAL_COMPILED_MODULES_REPLACEMENTS="pyyaml|yaml python-jose|jose python_jose|jose pyopenssl|OpenSSL mysql-connector-python|mysql mysql_connector_python|mysql linode-cli|linodecli linode_cli|linodecli speedtest-cli|speedtest"


MODULE_BIN_INCLUDES="linode-cli"
MODULE_BIN_INCLUDES="ansible ansible-playbook json2yaml yaml2json speedtest-cli"
MODULE_BIN_INCLUDES_DEFAULT="ansible-playbook"
MODULE_BIN_INCLUDES_FILE=~/.MODULE_BIN_INCLUDES.txt
MODULE_BIN_TOTAL_INCLUDES_FILE=~/.MODULE_BIN_TITAL_INCLUDES.txt

EXCLUDED_ADDITIONAL_MODULES="watchdog.utils.win32stat"
EXCLUDED_ANSIBLE_MODULES="$EXCLUDED_ADDITIONAL_MODULES ansible.modules.network ansible.modules.cloud ansible.modules.remote_management ansible.modules.storage ansible.modules.web_infrastructure ansible.modules.windows ansible.module_utils.network ansible.plugins.doc_fragments ansible.plugins.terminal ansible.modules.net_tools ansible.modules.monitoring.zabbix ansible.modules.messaging ansible.modules.identity ansible.modules.database.postgresql ansible.modules.database.proxysql ansible.modules.database.vertica ansible.modules.database.influxdb ansible.modules.clustering ansible.modules.source_control.bitbucket ansible.module_utils.aws ansible.plugins.cliconf"
ADDITIONAL_ANSIBLE_CALLLBACK_MODULES="https://raw.githubusercontent.com/codekipple/ansible-callback-concise/master/callback_plugins/codekipple_concise.py" # https://raw.githubusercontent.com/binRick/ansible-beautiful-output/master/callback_plugins/beautiful_output.py
ADDITIONAL_ANSIBLE_LIBRARY_MODULES="https://raw.githubusercontent.com/binRick/ansible-mysql-query/master/library/mysql_query.py https://raw.githubusercontent.com/ageis/ansible-module-ping/master/modules/icmp_ping.py https://raw.githubusercontent.com/cleargray/git_commit/master/git_commit.py"

findFileImports(){
    ./findimports/findimports.py -n ~/.venv/bin/ansible-playbook  -l 1 2>/dev/null|grep -v ':$'|sed 's/^[[:space:]]//g'
}

getBinModulesFile(){
    set -e
    modulesFile=$MODULE_BIN_INCLUDES_FILE
    totalModulesFile=$MODULE_BIN_TOTAL_INCLUDES_FILE
    echo -e "import os, sys, base64, setproctitle" > $modulesFile
    echo -e "import os, sys, base64, setproctitle" > $totalModulesFile
    for m in $(echo $MODULE_BIN_INCLUDES|tr '-' '_'|tr ' ' '\n'); do
        m="$(replaceModuleName $m)"
        echo -e "#import $m" >> $modulesFile
    done


    echo -e "_EXEC_BIN_MODULES = {}" >> $modulesFile
    echo -e "_EXEC_BIN_FUNCTIONS = {}" >> $totalModulesFile
    echo -e "_EXEC_BIN_OBJECT = {}" >> $totalModulesFile




    for m in $(echo $MODULE_BIN_INCLUDES|tr ' ' '\n'); do
        mF=~/.venv/bin/$m
        mFM=$(mktemp)
        mFM2=$(mktemp)
        b64="$(cat  $mF |base64 -w0)"
        _LINES=$(wc -l $mF |cut -d' ' -f1)
        _FUTURE_LINE_NUMBER=$(grep -n 'from __future__ import' $mF | cut -d':' -f1)
        FUNCTION_NAME="_EXEC_BIN_$(echo $m|tr '-' '_'|tr '[a-z]' '[A-Z]')"
        MODULE_STRING_NAME="_EXEC_BIN_$(echo $m|tr '-' '_'|tr '[a-z]' '[A-Z]')"
        proctitle="$(echo $m|tr '[A-z]' '[a-z]| tr '_' '-'')"

        if [[ "$_FUTURE_LINE_NUMBER" != "" ]]; then
            _LAST_LINES=$(($_LINES-$_FUTURE_LINE_NUMBER))
        else
            _LAST_LINES=$(($_LINES-1))
        fi

        tail -n $_LAST_LINES $mF > $mFM2
        sed -i 's/^/    /g' $mFM2
        echo -e "def ${FUNCTION_NAME}():" > $mFM
        cat $mFM2 >> $mFM
        chmod +x $mFM
        set -e
        python3 -m py_compile $mFM
        cat $mFM >> $totalModulesFile


        m="$(echo $m|tr '-' '_'|tr '[a-z]' '[A-Z]')"
        echo -e "_EXEC_BIN_MODULES[\"$m\"] = \"$b64\"" >> $modulesFile
        echo -e "\n\n_EXEC_BIN_FUNCTIONS[\"$m\"] = {\"FUNCTION_NAME\": \"${FUNCTION_NAME}\"}\n\n" >> $totalModulesFile
    
        >&2 echo -e "    Module :: [$m]  :: \n \
                        _LINES=$_LINES mFM=$mFM FUNCTION_NAME=$FUNCTION_NAME \n \
                        _FUTURE_LINE_NUMBER=$_FUTURE_LINE_NUMBER _LAST_LINES=$_LAST_LINES"

        echo -e "\n\nif \"${MODULE_STRING_NAME}\" in os.environ.keys():" >> $totalModulesFile
        echo -e "  setproctitle.setproctitle(\"$proctitle\")" >> $totalModulesFile
        echo -e "  sys.argv[0] = \"${proctitle}\"" >> $totalModulesFile
        echo -e "  eval(${FUNCTION_NAME}())" >> $totalModulesFile
        echo -e "  #globals()['%s' % ${FUNCTION_NAME}]()" >> $totalModulesFile
        echo -e "  #getattr(sys.modules[__name__], "%s" % ${FUNCTION_NAME})()" >> $totalModulesFile
        echo -e "\n\n" >> $totalModulesFile


    done

    echo -e "\n\nif \"_EXEC_BIN_list\" in os.environ.keys():" >> $modulesFile
    echo -e "  print(\"\\\\n\".join(_EXEC_BIN_MODULES.keys()))" >> $modulesFile
    echo -e "  sys.exit(0)\n\n" >> $modulesFile

    for m in $(echo $MODULE_BIN_INCLUDES|tr ' ' '\n'); do
        MODULE_STRING_NAME="_EXEC_BIN_$(echo $m|tr '-' '_'|tr '[a-z]' '[A-Z]')"
        proctitle="$(echo $m|tr '[A-z]' '[a-z]| tr '_' '-'')"
        echo -e "\n\nif \"${MODULE_STRING_NAME}\" in os.environ.keys():" >> $modulesFile
        echo -e "  setproctitle.setproctitle(\"$proctitle\")" >> $modulesFile
        echo -e "  sys.argv[0] = \"$proctitle\"" >> $modulesFile
        echo -e "  sys.exit(exec(base64.b64decode(_EXEC_BIN_MODULES[\"$m\"]).decode()))\n" >> $modulesFile


    done


    echo -e "\n\nif \"_EXEC_BIN_list\" in os.environ.keys():" >> $totalModulesFile
    echo -e "  print(\"\\\\n\".join(_EXEC_BIN_FUNCTIONS.keys()))" >> $totalModulesFile
    echo -e "  sys.exit(0)\n\n" >> $totalModulesFile

    echo -e "\n\nif len(sys.argv) == 2 and sys.argv[1] == \"--list-modules\":" >> $totalModulesFile
    echo -e "  print(\"\\\\n\".join(_EXEC_BIN_FUNCTIONS.keys()))" >> $totalModulesFile
    echo -e "  sys.exit(0)\n\n" >> $totalModulesFile

    echo -e "#getattr(sys.modules[__name__], "_EXEC_BIN_%s" % $(echo $MODULE_BIN_INCLUDES_DEFAULT|tr '-' '_'|tr '[a-z]' '[A-Z]'))()\n\n" >> $totalModulesFile
    echo -e "eval(_EXEC_BIN_$(echo $MODULE_BIN_INCLUDES_DEFAULT|tr '-' '_'|tr '[a-z]' '[A-Z]')())" >> $totalModulesFile


    echo $modulesFile
    #echo $totalModulesFile
}
mangleMainBinary(){
    set -e
    PATCHED_MAIN_BINARY=$(mktemp)
    TF=$(getBinModulesFile)
    command cp -f $TF $PATCHED_MAIN_BINARY
    #echo TF=$TF
    #exit 1


if [[ "1" == "" ]]; then
    _LINES=$(wc -l $MAIN_BINARY |cut -d' ' -f1)
    _FUTURE_LINE_NUMBER=$(grep -n 'from __future__ import' $MAIN_BINARY | cut -d':' -f1)
    _LAST_LINES=$(($_LINES-$_FUTURE_LINE_NUMBER))

(
    echo _LINES=$_LINES
    echo _FUTURE_LINE_NUMBER=$_FUTURE_LINE_NUMBER
    echo _LAST_LINES=$_LAST_LINES
    echo PATCHED_MAIN_BINARY=$PATCHED_MAIN_BINARY
    echo "PATCHED_MAIN_BINARY=$PATCHED_MAIN_BINARY" >> /tmp/PATCHED_MAIN_BINARIES.txt
) >&2


    head -n $_FUTURE_LINE_NUMBER $MAIN_BINARY > $PATCHED_MAIN_BINARY
    echo -e "\n\n" >> $PATCHED_MAIN_BINARY
    cat $TF >> $PATCHED_MAIN_BINARY
    echo -e "\n\n" >> $PATCHED_MAIN_BINARY
    tail -n $_LAST_LINES $MAIN_BINARY >> $PATCHED_MAIN_BINARY
fi

    echo $PATCHED_MAIN_BINARY

    #wc -l $PATCHED_MAIN_BINARY $MAIN_BINARY $TF
}


setupSshAgent(){
    if [ "$PRIVATE_KEY_ENCODED" == "" ]; then
        echo
        echo PRIVATE_KEY_ENCODED environment variable needs to contain private key
        echo "You can create it using \"PRIVATE_KEY_ENCODED=\$(cat /path/to/key | base64 -w0)\""
        echo
        echo
        exit 1
    fi
    set -e
    export SSH_AUTH_SOCK="$(mktemp -u -p ~ --suffix _sshAgent_socket)"
    coproc agentProcess { exec ssh-agent -dsa $SSH_AUTH_SOCK; }
    export K="$(cat BORG_KEY |base64 -w0)"
    echo $PRIVATE_KEY_ENCODED | base64 -d | ssh-add -
}

CREATED=0
BORG_CREATE_COMPRESSION="none"
BORG_CREATE_COMPRESSION="lzma" # Better Compression
BORG_CREATE_COMPRESSION="lz4"  # Faster
BORG_CREATE_COMPRESSION="auto,lzma,6"
ANSIBLE_TEST_ENV="ANSIBLE_NOCOWS=True ANSIBLE_PYTHON_INTERPRETER=auto_silent ANSIBLE_FORCE_COLOR=1 ANSIBLE_VERBOSITY=0 ANSIBLE_DEBUG=False ANSIBLE_LOCALHOST_WARNING=False ANSIBLE_SYSTEM_WARNINGS=True ANSIBLE_RETRY_FILES_ENABLED=False ANSIBLE_DISPLAY_ARGS_TO_STDOUT=False ANSIBLE_DEPRECATION_WARNINGS=False ANSIBLE_NO_TARGET_SYSLOG=True"
PLAYBOOK_FILE=~/.tp.yaml
start_ts="$(date +%s)"

if [[ "$BUILD_ONLY" != "1" ]]; then
	if [ "$DELETE_ARCHIVE" == "1" ]; then
	    echo "Deleting ${BORG_ARCHIVE}..."
	    rm -rf $BORG_ARCHIVE
	fi
fi

if [ "$QTY" == "" ]; then
    QUANTITY_OF_LATEST_ANSIBLE_RELEASES=10
else
    QUANTITY_OF_LATEST_ANSIBLE_RELEASES="$QTY"
fi
export BORG_PASSPHRASE="123123"

BORG_BINARY="borg-linux64"
BORG_OPTIONS="--lock-wait 300"

JQ="$(which jq)"
set +e; $JQ --version >/dev/null 2>&1 || {
    mkdir -p ~/.local/bin
    wget -4 https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 -O ~/.local/bin/jq
    chmod +x ~/.local/bin/jq
    export JQ=~/.local/bin/jq
}
set -e

writeTestPlaybook(){
    cat > $PLAYBOOK_FILE <<EOF
---
- name: test playbook
  hosts: all
  gather_facts: true
  connection: local
  become: false
  vars:
    dbCol1: id
    dbCol1Val: 10
    dbCol2: testval
    dbCol2Val: val12345
    dbCredentials:
      db_name: testdb
      db_host: localhost
      db_port: 3306
      db_username: testuser
      db_password: testpass123
  tasks:
  - name: pwd test
    command: pwd
    register: pwd
  - name: debug pwd
    debug:
      var: pwd
  - name: id test
    command: id
    register: id
  - name: debug id
    debug:
      var: id
  - name: icmp_ping module test
    icmp_ping:
      dest: 127.0.0.1
#  - name: mysql_query module test
#    mysql_query:
#      table: mod_vpntech_vpn_clients
#      db: '{{dbCredentials.db_name}}'
#      login_host: '{{dbCredentials.db_host}}'
#      login_port: '{{dbCredentials.db_port|default(3306)}}'
#      login_user: '{{dbCredentials.db_username}}'
#      login_password: '{{dbCredentials.db_password}}'
#      identifiers:
#        '{{dbCol1}}': '{{dbCol1Val}}'
#      values:
#        '{{dbCol2}}': '{{dbCol2Val}}'
...
EOF
echo $PLAYBOOK_FILE
}

installJo(){
  set +e
  command jo -v >/dev/null 2>&1 || \
     ~/.local/bin/jo -v >/dev/null 2>&1 || {
   (
    cd
    set +e
    rm -rf jo-1.2.tar.gz
    set -e
    wget -4 https://github.com/jpmens/jo/releases/download/1.2/jo-1.2.tar.gz
    tar zxvf jo-1.2.tar.gz
    cd jo-1.2
    (./configure --prefix=/usr/local && make) >/dev/null
    ./jo -v >/dev/null
    set +e
    mkdir -p ~/.local/bin
    set -e
    cp jo ~/.local/bin/.
    alias jo=~/.local/bin/jo
   )
   set -e
  }
}

replaceModuleName(){
	_M="$1"
	for r in $(echo "$ADDITIONAL_COMPILED_MODULES_REPLACEMENTS"|tr ' ' '\n'); do
		s1="$(echo $r|cut -d'|' -f1)"
		s2="$(echo $r|cut -d'|' -f2)"
		if [[ "$s1" == "$_M" ]]; then
			__M="$_M"
			_M=$(echo $_M|sed "s/^$s1\$/$s2/g")
			>&2 echo -e "        Changed Module name from \"$__M\" -> \"$_M\" based on r=$r, s1=$s1, s2=$s2"
		else
			[[ "0" == "1" ]] && >&2 echo -e "       module \"$_M\" does not match s1 \"$s1\" "
		fi
	done
	echo "$_M"
}
limitAnsibleVersions(){
    if [[ "$LIMIT_ANSIBLE_VERSIONS" == "" ]]; then
        egrep "2.8.7"
    else
        egrep "$LIMIT_ANSIBLE_VERSIONS"
    fi
    #egrep "2.8.7|2.8.6"
}
findModules(){
	_M="$1"
	_M="$(replaceModuleName $_M)"
   (
	set -e
        cd $2/
	if [[ ! -d "$_M" ]]; then
		>&2  echo -e "\n\n    Module \"$_M\" Find Failed ->    Directory \"$_M\" Does not exist in $(pwd) !\n\n"
        echo $_M
	else
        find $_M \
                | grep '\.py$'|grep '/'  | sed 's/\.py//g' | sed 's/\/__init__//g'

        find $_M \
                | grep '\.py$'| grep __init__.py$ |grep '/'| grep '/' | sed 's/\/__init__.py$//g'
    fi
   ) | sort | uniq
}

excludeAnsibleModules(){
	egrep -v "$(echo $EXCLUDED_ANSIBLE_MODULES | tr ' ' '|')"
}

mangleModules(){
    sed 's/\//./g'| xargs -I % echo -e "         --hidden-import=\"%\" "
}


buildPyInstallerCommand(){
    _MAIN_BINARY="$1"
	ANSIBLE_MODULES="$(findModules ansible $(getSitePackagesPath) | mangleModules)"
	_ANSIBLE_MODULES="$(echo $ANSIBLE_MODULES | tr ' ' '\n'| excludeAnsibleModules|tr '\n' ' ')"

	#echo ANSIBLE_MODULES=$ANSIBLE_MODULES
	#echo _ANSIBLE_MODULES=$_ANSIBLE_MODULES

	(
		echo -n "ANSIBLE_MODULES chars: ";  echo $ANSIBLE_MODULES  |tr ' ' '\n' | wc -l
		echo -n "_ANSIBLE_MODULES chars: "; echo $_ANSIBLE_MODULES |tr ' ' '\n' | wc -l

		echo -n "ANSIBLE_MODULES chars: "; (echo $ANSIBLE_MODULES|wc -c)
		echo -n "_ANSIBLE_MODULES chars: "; (echo $_ANSIBLE_MODULES|wc -c)
	) >&2

	HIDDEN_ADDITIONAL_COMPILED_MODULES=""
	for m in $(echo $ADDITIONAL_COMPILED_MODULES|sed 's/-/_/g' | tr -s ' ' '\n'); do 
		HIDDEN_ADDITIONAL_COMPILED_MODULES="$HIDDEN_ADDITIONAL_COMPILED_MODULES $(findModules $m $(getSitePackagesPath) | mangleModules)"
	done
	(
	 	echo HIDDEN_ADDITIONAL_COMPILED_MODULES=$HIDDEN_ADDITIONAL_COMPILED_MODULES
	) >&2


	echo pyinstaller \
		-n ansible-playbook \
		--$type -y --clean \
		--distpath $DIST_PATH \
		   \
		    --add-data .venv/lib/python3.6/site-packages/ansible/config/base.yml:ansible/config \
		    --add-data .venv/lib/python3.6/site-packages/ansible/config/module_defaults.yml:ansible/config \
		    --add-data .venv/lib/python3.6/site-packages/ansible/utils/shlex.py:ansible/utils \
		    --add-data .venv/lib/python3.6/site-packages/ansible/plugins/cache:ansible/plugins/cache \
		    --add-data .venv/lib/python3.6/site-packages/ansible/module_utils:ansible/module_utils \
		    --add-data .venv/lib/python3.6/site-packages/ansible/modules:ansible/modules \
		    --add-data .venv/lib/python3.6/site-packages/ansible/plugins/inventory:ansible/plugins/inventory \
		    --add-data .venv/lib/python3.6/site-packages/ansible/plugins:ansible/plugins \
		    --add-data .venv/lib/python3.6/site-packages/ansible/executor/discovery/python_target.py:ansible/executor/discovery \
		   \
		    ${HIDDEN_ADDITIONAL_COMPILED_MODULES} \
		    --hidden-import=configparser \
		    --hidden-import=distutils.spawn \
		    --hidden-import=xml.etree \
		    --hidden-import=pty \
		    --hidden-import=distutils.version \
		    --hidden-import=xml.etree.ElementTree \
		    --hidden-import=csv \
		    --hidden-import=smtplib \
		    --hidden-import=logging.handlers \
		   \
			${_ANSIBLE_MODULES} \
		    \
		     $_MAIN_BINARY

}

ansibleReleaseInfo(){
    curl -s4 https://pypi.org/pypi/ansible/json |jq ".releases[\"$1\"]"
}

validateAnsible(){
        ls -alhS $DIST_PATH/ansible-playbook
        $DIST_PATH/ansible-playbook --version
}

ignoreAnsibleVersions(){
    grep -v "^2.7" \
        |grep -v "^2.6"
}

getSitePackagesPath(){
    pip show ansible|grep ^Location:|cut -d' ' -f2| grep "^\/"|head -n 1
}
getAnsiblePath(){
    echo $(getSitePackagesPath)/ansible
}
getAnsiblePluginsPath(){
    echo $(getAnsiblePath)/plugins
}
getAnsibleModulesPath(){
    echo $(getAnsiblePath)/modules
}

addAdditionalAnsibleModules(){
    MODULE_TYPE=$1
    MODULE_TYPE_DIR=$2
    MODULES="$3"
    for m in $(echo "$MODULES"|tr ' ' '\n'); do
        mFile="$(basename $m)"
        if [[ $m == http* ]]; then
            if [ "$DEBUG_CMD" == "1" ]; then
              echo url detected $m
	    fi
            mT=$(mktemp -d)
            (cd $mT && curl -s $m > $mFile)
            _m=$mT/$(basename $m)
            if [ "$DEBUG_CMD" == "1" ]; then
              echo _m=$_m
              echo m=$m
	    fi
            m=$_m  
        fi
        mDir="$(dirname $m)"
        mCmdDir="$(getAnsiblePath)/${MODULE_TYPE}/${MODULE_TYPE_DIR}"
	if [[ ! -d "$mCmdDir" ]]; then mkdir -p $mCmdDir; fi
        mCmd="cp $mDir/$mFile $mCmdDir/$mFile"
        if [ "$DEBUG_CMD" == "1" ]; then
		echo mCmdDir=$mCmdDir
		echo mCmd=$mCmd
	fi
        eval $mCmd
    done
}

getAnsibleVersions(){
    curl -s4 https://pypi.org/pypi/ansible/json \
        | $JQ '.releases' | $JQ keys| grep '"[0-9]\.[0-9]\.[0-9].*"' \
        | sed 's/"//g'|sed 's/,//g' \
        | sed 's/[[:space:]]//g'|sort -r \
        | ignoreAnsibleVersions \
        | limitAnsibleVersions \
        | head -n $QUANTITY_OF_LATEST_ANSIBLE_RELEASES
}
export ANSIBLE_VERSIONS="$(getAnsibleVersions|tr '\n' ' ')"

set +e; $BORG_BINARY --version >/dev/null 2>&1 || {
    mkdir -p ~/.local/bin
    wget https://github.com/borgbackup/borg/releases/download/1.1.10/borg-linux64 -O ~/.local/bin/borg-linux64
    chmod +x ~/.local/bin/borg-linux64
    export BORG_BINARY=~/.local/bin/borg-linux64
    alias borg="$BORG_BINARY"
    alias borg-linux64="$BORG_BINARY"
}

doMain(){
    set -e
    installJo
    if [[ "$BUILD_ONLY" != "1" ]]; then
	    if [ ! -d $BORG_ARCHIVE ]; then
		$BORG_BINARY init --encryption repokey --storage-quota $BORG_ARCHIVE_QUOTA --make-parent-dirs $BORG_ARCHIVE 2>/dev/null
	    fi
	    $BORG_BINARY $BORG_OPTIONS info $BORG_ARCHIVE
	    $BORG_BINARY $BORG_OPTIONS list $BORG_ARCHIVE
    fi
    for ANSIBLE_VERSION in $ANSIBLE_VERSIONS; do
      for type in $TYPES; do
        pb_start_ts="$(date +%s)"
        cd
        DIST_PATH=~/ansible-playbook-$ANSIBLE_VERSION-$type
        set +e
    	if [[ "$BUILD_ONLY" != "1" ]]; then
		$BORG_BINARY $BORG_OPTIONS list $BORG_ARCHIVE | grep "^${ANSIBLE_VERSION}-${type}" >/dev/null && {
		    echo "$ANSIBLE_VERSION ($type) exists in $BORG_ARCHIVE. Skipping..";
		    continue;
		}
	fi
        set -e
        >&2 echo "Processing $ANSIBLE_VERSION $type"
        cd
        if [ "$type" == "onefile" ]; then
            PLAYBOOK_BINARY_PATH=$DIST_PATH/ansible-playbook
        elif [ "$type" == "onedir" ]; then
            PLAYBOOK_BINARY_PATH=$DIST_PATH/ansible-playbook/ansible-playbook
        else
            echo Failure
            exit 1
        fi

        if [ ! -d .venv ]; then
            python3 -m venv .venv
        fi
        source .venv/bin/activate
        
        pip install pip --upgrade -q >/dev/null
        pip install pyinstaller --upgrade -q >/dev/null
        
        if [ -d $DIST_PATH ]; then rm -rf $DIST_PATH; fi
        pip uninstall ansible --yes -q 2>/dev/null > /dev/null
        pip install "ansible==${ANSIBLE_VERSION}" --upgrade --force -q >/dev/null
        pip install $ADDITIONAL_COMPILED_MODULES --force --upgrade -q >/dev/null
        pip freeze -l >/dev/null


        addAdditionalAnsibleModules plugins callback "$ADDITIONAL_ANSIBLE_CALLLBACK_MODULES"
        addAdditionalAnsibleModules modules library "$ADDITIONAL_ANSIBLE_LIBRARY_MODULES"
	#exit

    >&2 echo "Manging Main Binary......"
    NEW_MAIN_BINARY=$(mangleMainBinary)
    ls -al $MAIN_BINARY $NEW_MAIN_BINARY
    #mv $MAIN_BINARY ${MAIN_BINARY}.orig
    #mv $NEW_MAIN_BINARY $MAIN_BINARY
    chmod 755 $MAIN_BINARY


        CMD="$(buildPyInstallerCommand $MAIN_BINARY)"
        if [ "$DEBUG_CMD" == "1" ]; then
            echo $CMD
            exit 
        fi
        ANSIBLE_HIDDEN_IMPORTS_QTY="$(echo "$CMD" | tr ' ' '\n'|grep -c hidden-import)"
	#findModules ansible $(getSitePackagesPath) | mangleModules|tr ' ' '\n'|grep '^--hidden-import='|wc -l)"
        >&2 echo "Building binary with $ANSIBLE_HIDDEN_IMPORTS_QTY hidden modules"




	set +e
    eval $CMD
	exit_code=$?
	if [[ "$exit_code" != "0" ]]; then
		rF=$(mktemp)
		echo "$CMD" >> $rF
		echo -e "\n\nBuild Failed\n\nBuild Command saved to file $rF\n\n"
		exit 1
	fi
	set -e
        >&2 echo "Finished Building binary"
        pb_duration=$(($(date +%s)-$pb_start_ts))

        set -e
        file $PLAYBOOK_BINARY_PATH | grep '^ansible-playbook' | grep ': ELF 64-bit LSB executable, x86-64' && >&2 echo Valid File
        $PLAYBOOK_BINARY_PATH --version | grep '^ansible-playbook $ANSIBLE_VERSION' && >&2 echo Valid Version
        
        >&2 echo "Configuring Ansible Base Environment.."
        source <(echo $ANSIBLE_TEST_ENV |tr ' ' '\n'|xargs -I % echo export %)

        testAnsible(){
            cmd="$PLAYBOOK_BINARY_PATH -i localhost, $(writeTestPlaybook)"
       	    echo $cmd;
	        eval $cmd;
        }

        >&2 echo "Executing Test Playbook"
        ANSIBLE_DISPLAY_ARGS_TO_STDOUT=False \
            testAnsible

        >&2 echo "Executing Test Playbook with yaml stdout callback"
        ANSIBLE_DISPLAY_ARGS_TO_STDOUT=False \
        ANSIBLE_STDOUT_CALLBACK=yaml \
            testAnsible

        >&2 echo "Executing Test Playbook with unixy stdout callback"
        ANSIBLE_DISPLAY_ARGS_TO_STDOUT=False \
        ANSIBLE_STDOUT_CALLBACK=unixy \
            testAnsible

        >&2 echo "Executing Test Playbook with codekipple_concise stdout callback"
        ANSIBLE_DISPLAY_ARGS_TO_STDOUT=False \
        ANSIBLE_STDOUT_CALLBACK=codekipple_concise \
            testAnsible

#        >&2 echo "Executing Test Playbook with beautiful_output stdout callback"
#        ANSIBLE_DISPLAY_ARGS_TO_STDOUT=False \
#        ANSIBLE_STDOUT_CALLBACK=beautiful_output \
#            testAnsible

        cd $DIST_PATH

        ansibleReleaseInfo $ANSIBLE_VERSION | $JQ '.[]' > .ANSIBLE-RELEASE.JSON;

        jo -p ended_ts=$(date +%s) version=$ANSIBLE_VERSION type=$type buildTime=$pb_duration \
              compression=$BORG_CREATE_COMPRESSION hostname="$(hostname -f)" os="$(uname)" \
              arch="$(uname -m)" kernel="$(uname -r)" distro="$(cat /etc/redhat-release)" \
              ansible_modules_qty="$ANSIBLE_MODULES_QTY" \
          > .METADATA.JSON

        COMMENT="ansible-playbook version=${ANSIBLE_VERSION} type=$type buildTime=$pb_duration \
                 compression=$BORG_CREATE_COMPRESSION hostname=$(hostname -f) os=$(uname) \
                 user="$USER" buildStartTime="$pb_start_ts" \
                 arch=$(uname -m) kernel=$(uname -r) distro=$(cat /etc/redhat-release)"


        if [[ "$BUILD_ONLY" == "1" ]]; then
               echo "DIST_PATH=$DIST_PATH"
               exit 0
        fi

	if [[ "$BUILD_ONLY" != "1" ]]; then
		$BORG_BINARY $BORG_OPTIONS create \
		    --compression $BORG_CREATE_COMPRESSION \
		    --progress --comment "$COMMENT" -v --stats $BORG_ARCHIVE::${ANSIBLE_VERSION}-${type} \
		    ansible-playbook .METADATA.JSON .ANSIBLE-RELEASE.JSON
	fi

        CREATED=$((CREATED+1))
        cd
        rm -rf $DIST_PATH

      done
    done
    duration=$(($(date +%s)-$start_ts))

    if [[ "$BUILD_ONLY" != "1" ]]; then
	    $BORG_BINARY $BORG_OPTIONS info $BORG_ARCHIVE
	    $BORG_BINARY $BORG_OPTIONS list $BORG_ARCHIVE
    fi

    echo "OK- Created $CREATED ansible-playbook binaries in $duration seconds."
}

doMain
