#!/usr/bin/env bash
umask 002
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source .ansi
export origDir="$(pwd)"
export START_DIR=$(mktemp -d)
cd $START_DIR
ANSIBLE_CONFIG_FILE="$origDir/files/ansible.cfg"
BORG_ARCHIVE_QUOTA="5G"  # Max Disk Space borg repo can use
BORG_ARCHIVE=~/ansible-playbook.borg
BORG_SSH_KEY="BORG_KEY"
BORG_SSH_PORT=22
BORG_SSH_HOST=web1
BORG_SSH_USER=BORG
VENV_PATH=~/.venv-ansible-bundler
WGET_ARGS="-4 --no-check-certificate"
export SPEC_FILES_DIR=$(mktemp -d --suffix __spec_files__)
MAIN_BINARY="$VENV_PATH/bin/ansible-playbook"
[[ "$INCLUDE_ALL_ANSIBLE_MODULES" == "" ]] && export INCLUDE_ALL_ANSIBLE_MODULES=1
[[ "$USE_MERGED_PY_INSTALL_METHOD" == "" ]] && export USE_MERGED_PY_INSTALL_METHOD=0
[[ "$USE_PYINSTALLER_SPEC_METHOD" == "" ]] && export USE_PYINSTALLER_SPEC_METHOD=0
[[ "$DEBUG_MAIN_BINARY_BUILD" == "" ]] && export DEBUG_MAIN_BINARY_BUILD="0"
[[ "$MANGLE_MAIN_BINARY" == "" ]] && export MANGLE_MAIN_BINARY="0"
[[ "$INCLUDE_ANSIBLE_TOOLS" == "" ]] && export INCLUDE_ANSIBLE_TOOLS="0"
[[ "$BUILD_ONLY" == "" ]] && export BUILD_ONLY=1
[[ "$DEBUG_CMD" == "" ]] && export DEBUG_CMD=0
CLEAN_BUILD="1"
TYPES="onedir"

PYARMOR_CMD_FILE="/tmp/PYARMOR_CMD.txt"
PYARMOR_OUTPUT_PATH="/tmp/pyarmor.out"
REMOVE_INCLUDED_TOOL_COMMENTS=1
ANSIBLE_TOOLS="ansible-config"
MANGLE_SCRIPT_NAME="mangleSpec.sh"
MANGLE_SCRIPT="./$MANGLE_SCRIPT_NAME"

export MANGLE_SCRIPT_PATH="$origDir/$MANGLE_SCRIPT_NAME"

if ! command -v shc >/dev/null 2>/dev/null; then
    >&2 echo shc not found in PATH
fi


PIP_INSTALL_MODULES_MODE=parallel

_RM_PATHS="\
   ansible/modules/web_infrastructure
"
MODULE_LAUNCHERS_FILE=$(mktemp)

MANUAL_HIDDEN_IMPORTS="--hidden-import=\"configparser\" \
		    --hidden-import=\"distutils.spawn\" \
		    --hidden-import=\"xml.etree\" \
		    --hidden-import=\"pty\" \
		    --hidden-import=\"distutils.version\" \
		    --hidden-import=\"xml.etree.ElementTree\" \
		    --hidden-import=\"csv\" \
		    --hidden-import=\"smtplib\" \
		    --hidden-import=\"logging.handlers\" \
"

ADDITIONAL_COMPILED_MODULES="simplejson terminaltables psutil loguru json2yaml setproctitle speedtest-cli pyyaml netaddr configparser urllib3 jmespath paramiko pyaml docopt"

source $origDir/constants.sh


MODULE_BIN_INCLUDES="ansible-playbook json2yaml yaml2json speedtest-cli ansible ansible-config"
COMPILE_MODULE_BIN_INCLUDES="1"
MODULE_BIN_INCLUDES_DEFAULT="ansible-playbook"
MODULE_BIN_INCLUDES_FILE=~/.MODULE_BIN_INCLUDES.txt
MODULE_BIN_TOTAL_INCLUDES_FILE=~/.MODULE_BIN_TITAL_INCLUDES.txt



#ADDITIONAL_ANSIBLE_CALLLBACK_MODULES=""
ADDITIONAL_ANSIBLE_CALLLBACK_MODULES="https://raw.githubusercontent.com/binRick/ansible-callback-concise/master/callback_plugins/codekipple_concise.py https://raw.githubusercontent.com/binRick/ansible-beautiful-output/master/callback_plugins/beautiful_output.py https://raw.githubusercontent.com/binRick/ansible-json-audit-log/master/callback/json_audit.py"

#ADDITIONAL_ANSIBLE_LIBRARY_MODULES=""
ADDITIONAL_ANSIBLE_LIBRARY_MODULES="https://raw.githubusercontent.com/binRick/ansible-mysql-query/master/library/mysql_query.py https://raw.githubusercontent.com/ageis/ansible-module-ping/master/modules/icmp_ping.py https://raw.githubusercontent.com/cleargray/git_commit/master/git_commit.py https://raw.githubusercontent.com/binRick/mysql_database_query/master/mysql_database_query.py"

findFileImports(){
    ./findimports/findimports.py -n $VENV_PATH/bin/ansible-playbook  -l 1 2>/dev/null|grep -v ':$'|sed 's/^[[:space:]]//g'
}

getBinModulesFile(){
    set -e

    modulesFile=$MODULE_BIN_INCLUDES_FILE
    totalModulesFile=$MODULE_BIN_TOTAL_INCLUDES_FILE

    echo -e "import os, sys, base64, setproctitle" > $modulesFile
    echo -e "import os, sys, base64, setproctitle" > $totalModulesFile
    >&2 echo "$MODULE_BIN_INCLUDEs=\"$MODULE_BIN_INCLUDES\""
    for m in $(echo $MODULE_BIN_INCLUDES|tr '-' '_'|tr ' ' '\n'); do
        m="$(replaceModuleName $m)"
        echo -e "#import $m" >> $modulesFile
    done


    echo -e "_EXEC_BIN_MODULES = {}" >> $modulesFile
    echo -e "_EXEC_BIN_FUNCTIONS = {}" >> $totalModulesFile
    echo -e "_EXEC_BIN_OBJECT = {}" >> $totalModulesFile

    for m in $(echo $MODULE_BIN_INCLUDES|tr ' ' '\n'); do
        mF=$VENV_PATH/bin/$m
        mFM=$(mktemp)
        mFM2=$(mktemp)
        b64="$(cat  $mF |base64 -w0)"
        _LINES=$(wc -l $mF |cut -d' ' -f1)
        _FUTURE_LINE_NUMBER=$(grep -n 'from __future__ import' $mF | cut -d':' -f1)
        FUNCTION_NAME="_EXEC_BIN_$(echo $m|tr '-' '_'|tr '[a-z]' '[A-Z]')"
        MODULE_STRING_NAME="_EXEC_BIN_$(echo $m|tr '-' '_'|tr '[a-z]' '[A-Z]')"
        proctitle="$(echo $m|tr '[A-Z]' '[a-z]'| tr '_' '-')"

        >&2 echo "m=\"$m\" proctitle=\"$proctitle\""
        if [[ "$proctitle" == "" ]]; then
            echo "Invalid proctitle ($proctitle) for module $m"
            exit 1
        fi


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
        proctitle="$(echo $m|tr '[A-Z]' '[a-z]| tr '_' '-'')"
        echo -e "\n\nif \"${MODULE_STRING_NAME}\" in os.environ.keys():" >> $modulesFile
        echo -e "  setproctitle.setproctitle(\"$proctitle\")" >> $modulesFile
        echo -e "  sys.argv[0] = \"$proctitle\"" >> $modulesFile
        echo -e "  sys.exit(exec(base64.b64decode(_EXEC_BIN_MODULES[\"$m\".upper().replace('-','_')]).decode()))\n" >> $modulesFile
    done


    echo -e "\n\nif \"_EXEC_BIN_list\" in os.environ.keys():" >> $totalModulesFile
    echo -e "  print(\"\\\\n\".join(_EXEC_BIN_FUNCTIONS.keys()))" >> $totalModulesFile
    echo -e "  sys.exit(0)\n\n" >> $totalModulesFile

    echo -e "\n\nif len(sys.argv) == 2 and sys.argv[1] == \"--list-modules\":" >> $totalModulesFile
    echo -e "  print(\"\\\\n\".join(_EXEC_BIN_FUNCTIONS.keys()))" >> $totalModulesFile
    echo -e "  sys.exit(0)\n\n" >> $totalModulesFile

    echo -e "#getattr(sys.modules[__name__], "_EXEC_BIN_%s" % $(echo $MODULE_BIN_INCLUDES_DEFAULT|tr '-' '_'|tr '[a-z]' '[A-Z]'))()\n\n" >> $totalModulesFile
    echo -e "eval(_EXEC_BIN_$(echo $MODULE_BIN_INCLUDES_DEFAULT|tr '-' '_'|tr '[a-z]' '[A-Z]')())" >> $totalModulesFile

    if [[ "$modulesFile" == "" ]]; then
        echo -e "\nERROR: Invalid modulesFile \"$modulesFile\"\n"
        exit 1
    fi
    echo $modulesFile
    #echo $totalModulesFile
}

MANGLED_VARS_PATH=$(mktemp -d --suffix __compiler__mangled_vars_path__)
BIN_MODULES_PATH=$(mktemp -d --suffix __compiler__bin_modules__)

get_mangled_var(){
    (source $MANGLED_VARS_PATH/.${1}_mangled_vars.txt && echo ${!2})
}
ansi-exit_code(){
    >&2 ansi -n --cyan --bg-black "    "
    >&2 ansi --white --bg-black "  $(echo $1|sed 's/[[:space:]]/ /g')  "
    >&2 ansi -n --cyan --bg-black "           Exited  "
    >&2 ansi --yellow --bg-black $2
}

get_mangle_vars_file(){
    x="$(basename $1 .py)"
    x_mangle_vars="$MANGLED_VARS_PATH/.${x}_mangled_vars.txt"
    echo $x_mangle_vars
}

mangleMainBinary(){
    set -e
    set -x
    PATCHED_MAIN_BINARY=$(mktemp)
    TF=$(getBinModulesFile)
    if [[ "$TF" == "" ]]; then
        echo -e "\nERROR: Invalid TF from getBinModulesFile()\n"
        exit 1
    fi
    >&2 echo TF=$TF
    >&2 echo PATCHED_MAIN_BINARY=$PATCHED_MAIN_BINARY
    mangle_cmd="command cp -f $TF $PATCHED_MAIN_BINARY"
    >&2 echo mangle_cmd=$mangle_cmd
    eval $mangle_cmd
    exit_code=$?
    if [[ "$exit_code" != "0" ]]; then
        echo -e "\nERROR: Mangle command \"$mangle_cmd\" exited $exit_code\n"
        exit $exit_code
    fi
    #exit 1

    #if [[ "1" == "" ]]; then
    if [[ "1" == "1" ]]; then
        _LINES=$(wc -l $MAIN_BINARY |cut -d' ' -f1)
        _FUTURE_LINE_NUMBER=$(grep -n 'from __future__ import' $MAIN_BINARY | cut -d':' -f1)

        >&2 echo _LINES=$_LINES
        >&2 echo _FUTURE_LINE_NUMBER=$_FUTURE_LINE_NUMBER
        >&2 echo MAIN_BINARY=$MAIN_BINARY

        if [[ "_FUTURE_LINE_NUMBER" != "" ]]; then
            _LAST_LINES=$(($_LINES-$_FUTURE_LINE_NUMBER))
        else
            _LAST_LINES=$_LINES
        fi

        >&2 echo _LAST_LINES=$_LAST_LINES

        (
         >&2   echo _LINES=$_LINES
         >&2   echo _FUTURE_LINE_NUMBER=$_FUTURE_LINE_NUMBER
         >&2   echo _LAST_LINES=$_LAST_LINES
         >&2   echo PATCHED_MAIN_BINARY=$PATCHED_MAIN_BINARY
         >&2   echo "PATCHED_MAIN_BINARY=$PATCHED_MAIN_BINARY" >> /tmp/PATCHED_MAIN_BINARIES.txt
        )


        head -n $_FUTURE_LINE_NUMBER $MAIN_BINARY > $PATCHED_MAIN_BINARY
        echo -e "\n\n" >> $PATCHED_MAIN_BINARY
        cat $TF >> $PATCHED_MAIN_BINARY
        echo -e "\n\n" >> $PATCHED_MAIN_BINARY
        tail -n $_LAST_LINES $MAIN_BINARY >> $PATCHED_MAIN_BINARY
    fi

    >&2 echo PATCHED_MAIN_BINARY=$PATCHED_MAIN_BINARY
    >&2 wc -l $PATCHED_MAIN_BINARY $MAIN_BINARY $TF

    echo $PATCHED_MAIN_BINARY
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
    wget $WGET_ARGS https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 -O ~/.local/bin/jq
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
    ignore_errors: yes
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
    wget $WGET_ARGS https://github.com/jpmens/jo/releases/download/1.2/jo-1.2.tar.gz
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


echo $origDir/utils.sh
source $origDir/utils.sh

#replaceModuleName(){
#	_ ="$1"
#	for r in $(echo "$ADDITIONAL_COMPILED_MODULES_REPLACEMENTS"|tr ' ' '\n'); do
#		s1="$(echo $r|cut -d'|' -f1)"
#		s2="$(echo $r|cut -d'|' -f2)"
#		if [[ "$s1" == "$_M" ]]; then
#			__M="$_M"
#			_M=$(echo $_M|sed "s/^$s1\$/$s2/g")
#			>&2 echo -e "        Changed Module name from \"$__M\" -> \"$_M\" based on r=$r, s1=$s1, s2=$s2"
#		else
#			[[ "0" == "1" ]] && >&2 echo -e "       module \"$_M\" does not match s1 \"$s1\" "
#		fi
#	done
#	echo "$_M"
#}


limitAnsibleVersions(){
    if [[ "$LIMIT_ANSIBLE_VERSIONS" == "" ]]; then
        egrep "2.8.8"
    else
        egrep "$LIMIT_ANSIBLE_VERSIONS"
    fi
}

excludeAnsibleModules(){
	egrep -v "$(echo $EXCLUDED_ANSIBLE_MODULES | tr ' ' '|')"
}


buildPyInstallerCommand(){
    _MAIN_BINARY="$1"
	if [[ "$INCLUDE_ALL_ANSIBLE_MODULES" == "1" ]]; then
	    am=$(mktemp)
	    fm=$(mktemp)
	    findModules_venv ansible > $fm
	    #echo fm=$fm
	    #echo $ANSIBLE_MODULES > $am
	    #echo am=$am
	    #exit
	    export ANSIBLE_MODULES="$(findModules ansible $(getSitePackagesPath) | mangleModules)"
	    export _ANSIBLE_MODULES="$(echo $ANSIBLE_MODULES | tr ' ' '\n'| excludeAnsibleModules|tr '\n' ' ')"
    else
        >&2 echo Skipping Ansible Modules
	    export ANSIBLE_MODULES=""
	    export _ANSIBLE_MODULES=""
    fi

	>&2 echo ANSIBLE_MODULES=$ANSIBLE_MODULES
	>&2 echo _ANSIBLE_MODULES=$_ANSIBLE_MODULES


	exit 232

	HIDDEN_ADDITIONAL_COMPILED_MODULES=""
	for m in $(echo $ADDITIONAL_COMPILED_MODULES|sed 's/-/_/g' | tr -s ' ' '\n'); do 
		HIDDEN_ADDITIONAL_COMPILED_MODULES="$HIDDEN_ADDITIONAL_COMPILED_MODULES $(findModules $m $(getSitePackagesPath) | mangleModules)"
	done
	(
	 	echo HIDDEN_ADDITIONAL_COMPILED_MODULES=HIDDEN_ADDITIONAL_COMPILED_MODULES
	) >&2

    _tf1="$(mktemp)"
    PYARMOR_CMD_E="-p ~/.venv-ansible-bundler/lib/python3.6/site-packages $HIDDEN_ADDITIONAL_COMPILED_MODULES $_ANSIBLE_MODULES $_ADD_DATAS $MANUAL_HIDDEN_IMPORTS"
    echo "$PYARMOR_CMD_E" > $_tf1
    sed -i 's/\\n/ /g' $_tf1
    sed -i 's/"//g' $_tf1
    #cat $_tf1
    #echo $_tf1
    PYARMOR_CMD_E="$(cat $_tf1)"
    echo "PYARMOR_CMD_E=\"$PYARMOR_CMD_E\""
    #exit 123


    PYARMOR_CMD="cp $_MAIN_BINARY ${_MAIN_BINARY}.py && pyarmor pack --debug -t PyInstaller --clean -O $PYARMOR_OUTPUT_PATH -e \" $PYARMOR_CMD_E \" ${_MAIN_BINARY}.py"
    echo $PYARMOR_CMD > $PYARMOR_CMD_FILE

    if [[ "$USE_PYINSTALLER_SPEC_METHOD" == "1" ]]; then
        if [[ "$USE_MERGED_PY_INSTALL_METHOD" == "0" ]]; then
                            $_ADD_DATAS \
                            $HIDDEN_ADDITIONAL_COMPILED_MODULES \
                            $MANUAL_HIDDEN_IMPORTS \
                            $_ANSIBLE_MODULES \
                    py_mkspec_cmd="pyi-makespec \
                            -p $VIRTUAL_ENV/lib64/python3.6/site-packages \
                               $_MAIN_BINARY"

                    SPEC_FILE="$(basename ${_MAIN_BINARY}).spec"

                    >&2 echo py_mkspec_cmd=$py_mkspec_cmd
                    >&2 echo SPEC_FILE=$SPEC_FILE

                    mkspec_out=$(mktemp)
                    mkspec_err=$(mktemp)
                    eval $py_mkspec_cmd > $mkspec_out 2> $mkspec_err
                    exit_code=$?
                    if [[ "$exit_code" != "0" ]]; then
                        cat $mkspec_out
                        cat $mkspec_err
                        echo -e "\n\nexit code $exit_code\n\n"
                        exit $exit_code
                    fi
                    >&2 echo py_mkspec exit_code=$exit_code
                    CREATED_SPEC_FILE="$(grep '^wrote ' $mkspec_out | tail -n1|cut -d' ' -f2)"
                    >&2 echo CREATED_SPEC_FILE=$CREATED_SPEC_FILE
                    cp $CREATED_SPEC_FILE $SPEC_FILE

                    
                    mangle_cmd="cp -f $MANGLE_SCRIPT_PATH $MANGLE_SCRIPT_NAME && ./$MANGLE_SCRIPT_NAME $SPEC_FILE"
                    >&2 echo mangle_cmd=$mangle_cmd
                    mangle_stdout=$(mktemp)
                    mangle_stderr=$(mktemp)
                    eval $mangle_cmd > $mangle_stdout 2>$mangle_stderr
                    exit_code=$?        
                    if [[ "$exit_code" != "0" ]]; then
                        cat $mangle_stdout
                        cat $mangle_stderr
                        echo -e "\n\nexit code $exit_code\n\n"
                        exit $exit_code
                    fi
                    >&2 ls $SPEC_FILE
                    export _ANSIBLE_PLAYBOOK_SPEC_FILE=$SPEC_FILE
                    export _PY_INSTALLER_TARGET=$SPEC_FILES_DIR/$_ANSIBLE_PLAYBOOK_SPEC_FILE
        else
            set -e
            echo -ne "\n"
            >&2 ansi --cyan Create Compined Spec File
            COMBINED_SPEC_FILE=""
            for x in $(echo $MODULE_BIN_INCLUDES|tr ' ' '\n'); do
                x="$(basename $x .py|sed 's/-//g'|sed 's/_//g'|sed 's/[[:space:]]//g')"
                COMBINED_SPEC_FILE="${COMBINED_SPEC_FILE}_${x}"
            done

            COMBINED_SPEC_FILE="${COMBINED_SPEC_FILE}.spec"
            COMBINED_SPEC_FILE="$(echo $COMBINED_SPEC_FILE | sed 's/^_//g')"
            COMBINED_SPEC_FILE="$SPEC_FILES_DIR/$(basename $COMBINED_SPEC_FILE)"

            [[ -f $COMBINED_SPEC_FILE ]] && rm $COMBINED_SPEC_FILE
            touch $COMBINED_SPEC_FILE
            >&2 ansi --green "OK - Created $COMBINED_SPEC_FILE"
            
            SAVE_DIR=$(pwd)
            PIP_INSTALL_MODULES_MODE="parallel"
            if [[ "$PIP_INSTALL_MODULES_MODE" == "parallel" ]]; then
                pip_cmd="pip install -q $(echo -e "$MODULE_BIN_INCLUDES"|tr '\n' ' '|tr ',' ' ')"
                echo -e pip_cmd=$pip_cmd
                eval $pip_cmd
            fi
            for M in $(echo $MODULE_BIN_INCLUDES|tr ' ' '\n'); do
                >&2 ansi --green Working on module $M
                M_b=$(basename $M)
                MODULE_BUILD_DIR=$(mktemp -d --suffix __compiler_module_${M})
                cd $MODULE_BUILD_DIR
                if [[ "$PIP_INSTALL_MODULES_MODE" != "parallel" ]]; then
                    >&2 ansi --magenta MODULE_BUILD_DIR=$MODULE_BUILD_DIR
                    >&2 ansi --green "  adding module $M"
                    add_cmd="pip install $M -q 2>/dev/null; cp $(which $M) $BIN_MODULES_PATH/$M; true"
                    >&2 ansi --cyan add_cmd=$add_cmd
                    set +e
                    eval $add_cmd
                    exit_code=$?
                    set -e
                    ansi-exit_code "$add_cmd" $exit_code
                fi
                if [[ ! -f $BIN_MODULES_PATH/$M ]]; then
                    echo cannot find file $M at $BIN_MODULES_PATH/$M
                    exit 100
                fi

                >&2 echo GENERATING SPEC FILE FOR MODULE $M
#                        $_ADD_DATAS \
#                        $HIDDEN_ADDITIONAL_COMPILED_MODULES \
#                        $MANUAL_HIDDEN_IMPORTS \
#                        $_ANSIBLE_MODULES \
                py_mkspec_cmd="pyi-makespec \
                        -p $VIRTUAL_ENV/lib64/python3.6/site-packages \
                           $BIN_MODULES_PATH/$M"
                SPEC_FILE="${M}.spec"
                mkspec_out=$(mktemp)
                mkspec_err=$(mktemp)
                eval $py_mkspec_cmd > $mkspec_out 2> $mkspec_err
                exit_code=$?
                ansi-exit_code "$py_mkspec_cmd" $exit_code
                CREATED_SPEC_FILE="$(grep '^wrote ' $mkspec_out | tail -n1|cut -d' ' -f2)"
                >&2 echo CREATED_SPEC_FILE=$CREATED_SPEC_FILE
                mangle_cmd="cp -f $MANGLE_SCRIPT_PATH $MANGLE_SCRIPT_NAME && ./$MANGLE_SCRIPT_NAME $SPEC_FILE"
                >&2 echo " [MODULE $M]: SPEC_FILE=$SPEC_FILE"
                >&2 echo py_mkspec_cmd=$py_mkspec_cmd
                >&2 echo mangle_cmd=$mangle_cmd
                mangle_stdout=$(mktemp)
                mangle_stderr=$(mktemp)
                eval $mangle_cmd > $mangle_stdout 2>$mangle_stderr
                exit_code=$?        
                if [[ "$exit_code" != "0" ]]; then
                    cat $mangle_stdout
                    cat $mangle_stderr
                    echo -e "\n\nexit code $exit_code\n\n"
                    exit $exit_code
                fi

                cp $mangle_stdout $(get_mangle_vars_file $(basename $M))
                >&2 ls $SPEC_FILE
                cp $SPEC_FILE $SPEC_FILES_DIR/.

            done

            cd $SAVE_DIR
            ls -al $SPEC_FILES_DIR
            ls -al $BIN_MODULES_PATH
            >&2 echo SPEC_FILES_DIR=$SPEC_FILES_DIR
            >&2 echo BIN_MODULES_PATH=$BIN_MODULES_PATH
            >&2 echo SAVE_DIR=$SAVE_DIR

#           exit 255

            >&2 ansi --cyan Assembling combined spec file from mangled spec files

            >&2 ansi --magenta " [Block Cipher]"
            for x in $(echo $MODULE_BIN_INCLUDES|tr ' ' '\n'); do
                x_orig="$x"
                x="$(basename $x .py)"
                x_spec="$SPEC_FILES_DIR/${x}.spec"
                mangle_cmd="$MANGLE_SCRIPT $x_spec"
                x_mangle_vars="$(get_mangle_vars_file $x_orig)"
                PYZ_file="$(get_mangled_var $x_orig PYZ)"
                EXE_file="$(get_mangled_var $x_orig EXE)"

                if ! grep -q '^block_cipher' $COMBINED_SPEC_FILE; then
                    cat "$(get_mangled_var $x_orig BLOCK_CIPHER)" >> $COMBINED_SPEC_FILE
                    >&2 ansi --green "   Added block Cipher!"
                fi
            done
            >&2 ansi --green " OK"

            echo -ne "\n\n" >> $COMBINED_SPEC_FILE
            for x in $(echo $MODULE_BIN_INCLUDES|tr ' ' '\n'); do
                x_orig="$x"
                x="$(basename $x .py)"
                x_spec="$SPEC_FILES_DIR/${x}.spec"
                x_mangle_vars="$(get_mangle_vars_file $x_orig)"
                for k in ANALYSIS; do
                    >&2 ansi --magenta " [$x_orig => $k]"
                    cat "$(get_mangled_var $x_orig $k)" >> $COMBINED_SPEC_FILE
                    echo -ne "\n" >> $COMBINED_SPEC_FILE
                    >&2 ansi --green "   OK"
                done
                echo -ne "\n\n" >> $COMBINED_SPEC_FILE
            done
            echo -ne "\n\n" >> $COMBINED_SPEC_FILE

            >&2 ansi --magenta " [Merge Statement]"
            echo -ne "\n" >> $COMBINED_SPEC_FILE
            merge_line="MERGE( (test_a, 'test', 'test'), (test1_a, 'test1', 'test1') )"
            merge_line="MERGE("
            for x in $(echo $MODULE_BIN_INCLUDES|tr ' ' '\n'); do
                x="$(basename $x .py)"
                script_line=" (${x}_a, '$x', '$x'),"
                merge_line="${merge_line}${script_line}"
            done
            merge_line="$(echo $merge_line|sed 's/,$//g')"
            merge_line="${merge_line} )"
            echo $merge_line >> $COMBINED_SPEC_FILE
            echo -ne "\n\n\n\n" >> $COMBINED_SPEC_FILE
            for x in $(echo $MODULE_BIN_INCLUDES|tr ' ' '\n'); do
                x_orig="$x"
                x="$(basename $x .py)"
                x_spec="$SPEC_FILES_DIR/${x}.spec"
                x_mangle_vars="$(get_mangle_vars_file $x_orig)"
                for k in PYZ EXE COLLECT; do
                    >&2 ansi --magenta " [$k]"
                    cat "$(get_mangled_var $x_orig $k)" >> $COMBINED_SPEC_FILE
                    echo -ne "\n" >> $COMBINED_SPEC_FILE
                    >&2 ansi --green "   OK"
                done
                echo -ne "\n\n" >> $COMBINED_SPEC_FILE
            done
            echo -ne "\n\n" >> $COMBINED_SPEC_FILE

            export _PY_INSTALLER_TARGET="$COMBINED_SPEC_FILE"
            if cat $_PY_INSTALLER_TARGET | grep -q '^_pyz = '; then 
                >&2 ansi --red Invalid PY Installer file $_PY_INSTALLER_TARGET
                exit 69
            fi 
            cat $_PY_INSTALLER_TARGET
            exit 169
    fi
        >&2 echo _PY_INSTALLER_TARGET=$_PY_INSTALLER_TARGET

        [[ "$_DEBUG_PY_INSTALLER" == "1" ]] && exit 666


    else

#replace '.spec' '' -- xxxxx
#replace 'ansible-playbook' '' -- xxxxx

      >&2 echo -e "   *** NOT USING SPEC MODE ***"
      export _PY_INSTALLER_TARGET=$_MAIN_BINARY

    fi



    cmd="pyinstaller \
        -n ansible-playbook \
        --$type -y --clean \
        --distpath $DIST_PATH \
           \
            $_ADD_DATAS \
           \
            ${HIDDEN_ADDITIONAL_COMPILED_MODULES} \
            ${MANUAL_HIDDEN_IMPORTS} \
           \
            ${_ANSIBLE_MODULES} \
            \
             $_PY_INSTALLER_TARGET"
    echo $cmd


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
#            if [ "$DEBUG_CMD" == "1" ]; then
#              echo url detected $m
#	    fi
            mT=$(mktemp -d)
            (cd $mT && curl -s $m > $mFile)
            _m=$mT/$(basename $m)
#            if [ "$DEBUG_CMD" == "1" ]; then
#              echo _m=$_m
#              echo m=$m
#	    fi
            m=$_m  
        fi
        mDir="$(dirname $m)"
        mCmdDir="$(getAnsiblePath)/${MODULE_TYPE}/${MODULE_TYPE_DIR}"
   	    if [[ ! -d "$mCmdDir" ]]; then mkdir -p $mCmdDir; fi
        mCmd="cp $mDir/$mFile $mCmdDir/$mFile"
#       if [ "$DEBUG_CMD" == "1" ]; then
#    		echo mCmdDir=$mCmdDir
#    		echo mCmd=$mCmd
#    	fi
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

if [[ ! -e ~/.local/bin/borg ]]; then
    mkdir -p ~/.local/bin
    wget $WGET_ARGS https://github.com/borgbackup/borg/releases/download/1.1.10/borg-linux64 -O ~/.local/bin/borg
    chmod +x ~/.local/bin/borg
    export BORG_BINARY=~/.local/bin/borg
    if [[ ! -f ~/.local/bin/borg-linux64 ]]; then cp ~/.local/bin/borg ~/.local/bin/borg-linux64; fi
    alias borg="$BORG_BINARY"
    alias borg-linux64="$BORG_BINARY"
fi

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

        echo venv=$VENV_PATH
        if [ ! -f $VENV_PATH/bin/activate ]; then
            python3 -m venv $VENV_PATH
        fi
        source $VENV_PATH/bin/activate
        
        pip install pip --upgrade -q >/dev/null
        pip install pyinstaller --upgrade -q >/dev/null
        if [[ "$CLEAN_BUILD" == "1" ]]; then        
            if [ -d $DIST_PATH ]; then rm -rf $DIST_PATH; fi
#            pip uninstall ansible --yes -q 2>/dev/null > /dev/null
        fi

        pip install "ansible==${ANSIBLE_VERSION}" -q >/dev/null
        pip install $ADDITIONAL_COMPILED_MODULES -q >/dev/null

        addAdditionalAnsibleModules plugins callback "$ADDITIONAL_ANSIBLE_CALLLBACK_MODULES"
        addAdditionalAnsibleModules modules library "$ADDITIONAL_ANSIBLE_LIBRARY_MODULES"




    ### Mangle binary
    if [[ "$MANGLE_MAIN_BINARY" == "1" ]]; then
        >&2 echo "Mangling Main Binary......"
        NEW_MAIN_BINARY=$(mangleMainBinary)
        if [[ "$NEW_MAIN_BINARY" == "" ]]; then
            echo Invalid NEW_MAIN_BINARY
            exit 1
        fi
    
        pwd
        ls -al $MAIN_BINARY $NEW_MAIN_BINARY
        cp $MAIN_BINARY ${MAIN_BINARY}.orig
        cp $NEW_MAIN_BINARY $MAIN_BINARY
        chmod 755 $MAIN_BINARY
    fi


        CMD="$(buildPyInstallerCommand $MAIN_BINARY|grep '^pyinstaller '|tail -n1)"
        if [ "$DEBUG_CMD" == "1" ]; then
            cmd_file=$(mktemp)
            echo $CMD > $cmd_file
            echo -e "\n\ncmd_file=$cmd_file\n"
            exit 
        fi
        ANSIBLE_HIDDEN_IMPORTS_QTY="$(echo "$CMD" | tr ' ' '\n'|grep -c hidden-import)"
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
[[ "$SKIP_RM_PYCACHE" != "1" ]] &&    find $DIST_PATH -type d|grep __pycache__$|xargs -I % rm -rf %
#    find $DIST_PATH -type f -name detailed.py|xargs -I %  unlink %
    $PLAYBOOK_BINARY_PATH --version | grep '^ansible-playbook $ANSIBLE_VERSION' && >&2 echo Valid Version
    file $PLAYBOOK_BINARY_PATH | grep '^ansible-playbook' | grep ': ELF 64-bit LSB executable, x86-64' && >&2 echo Valid File



    set -e

    if [[ "$MANGLE_MAIN_BINARY" == "1" ]]; then
        for m in $(echo $MODULE_BIN_INCLUDES|tr ' ' '\n'); do
            
            DDIR="$(dirname $PLAYBOOK_BINARY_PATH)"
            MF="$DDIR/${m}.sh"
            MF_bin="$DDIR/${m}.bin"
            _m="$(echo $m|tr '-' '_'|tr '[a-z]' '[A-z]')"
            >&2 echo "Creating Launcher Script for module \"$m\" in file \"$MF\", _m=\"$_m\""
            cp $origDir/moduleBinTemplate.sh.j2 $MF
            sed -i "s/{{MODULE_NAME}}/$_m/g" $MF
            chmod +x $MF
            chmod 755 $MF
            if [[ "$COMPILE_MODULE_BIN_INCLUDES" == "1" ]]; then
                shc_cmd="shc -r -f $MF -o $MF_bin"
                eval $shc_cmd
                e=$?
                if [[ "$e" != "0" ]]; then
                    echo "Failed to compile module $m using cmd \"$shc_cmd\", got exit code $e"
                    exit $e
                fi
                ls -al $MF $MF_bin
            fi
            echo "$MF" >> $MODULE_LAUNCHERS_FILE
        done
    fi

    echo MODULE_LAUNCHERS_FILE=$MODULE_LAUNCHERS_FILE
    #pwd
    #exit


    if [[ "1" == "0" ]]; then
        echo "Compiling with pyarmor :: $PYARMOR_CMD_FILE"
        bash $PYARMOR_CMD_FILE

        find $PYARMOR_OUTPUT_PATH -type d|grep __pycache__$|xargs -I % rm -rf %

        echo "Compiled $(find $PYARMOR_OUTPUT_PATH|wc -l) files to $PYARMOR_OUTPUT_PATH"



        exit 
    fi


    if [[ "$MANGLE_MAIN_BINARY" == "1" ]]; then
        #set +e
        >&2 echo "Testing mangled binary"
        TEST_MANGLED_CMD="_EXEC_BIN_list=1 sh -c \"$PLAYBOOK_BINARY_PATH\""
        TEST_MANGLED_OUTPUT_FILE=$(mktemp)
        echo TEST_MANGLED_CMD=$TEST_MANGLED_CMD
        echo TEST_MANGLED_OUTPUT_FILE=$TEST_MANGLED_OUTPUT_FILE

        eval $TEST_MANGLED_CMD > $TEST_MANGLED_OUTPUT_FILE
        exit_code=$?

	    if [[ "$exit_code" != "0" ]]; then
            echo "Mangled Binary Failed test Command: \"$TEST_MANGLED_CMD\" with exit code $exit_code"
            exit $exit_code
        else
            >&2 echo "Mangled binary passed tests"
            TEST_MANGLED_MODES="$(cat $TEST_MANGLED_OUTPUT_FILE)"
            TEST_MANGLED_MODES_QTY="$(echo $TEST_MANGLED_MODES|tr ' ' '\n' |wc -l)"
        fi

        MODULE_BIN_INCLUDES_QTY="$(echo $MODULE_BIN_INCLUDES|tr ' ' '\n' |wc -l)"
        if [[ "$MODULE_BIN_INCLUDES_QTY" != "$TEST_MANGLED_MODES_QTY" ]]; then
            echo "We requested $MODULE_BIN_INCLUDES_QTY modes but mangled binary only provided $TEST_MANGLED_MODES_QTY modes"
            exit 1
        fi

        if [[ "$DEBUG_MAIN_BINARY_BUILD" == "1" ]]; then
            echo "[DEBUG_MAIN_BINARY_BUILD] :: Seems OK with $TEST_MANGLED_MODES_QTY modes and we requsted $MODULE_BIN_INCLUDES_QTY modes!"
            exit
        fi
        set -e
    fi

        
        >&2 echo "Removing Paths.."
        for x in $_RM_PATHS; do
            rm_cmd="rm -rf $DIST_PATH/ansible-playbook/$x"
            >&2 echo -e "       Removing Path  \"$x\" with cmd \"$rm_cmd\""
            eval $rm_cmd
            
        done


        >&2 echo "Configuring Ansible Base Environment.."
        source <(echo $ANSIBLE_TEST_ENV |tr ' ' '\n'|xargs -I % echo export %)
        export ANSIBLE_CALLBACK_WHITELIST=""

        >&2 echo "Creating Ansible Configuration File.."
        ANSIBLE_CONFIG_FILENAME="$(basename $ANSIBLE_CONFIG_FILE)"
        ANSIBLE_CONFIG_FILENAME="$DIST_PATH/ansible-playbook/ansible.cfg"
        [[ -f "$ANSIBLE_CONFIG_FILENAME" ]] && unlink $ANSIBLE_CONFIG_FILENAME
        cp $ANSIBLE_CONFIG_FILE $ANSIBLE_CONFIG_FILENAME

        if [[ "$INCLUDE_ANSIBLE_TOOLS" == "1" ]]; then
            echo -e "\n\nIncluding Ansible Tools\n\n"
            echo $ANSIBLE_TOOLS
            for T in $(echo "$ANSIBLE_TOOLS"|tr ' ' '\n'|grep -v "^$"); do
                echo -e "  working on tool $T..."
                TP=$(which $T)
                echo -e "       found it in path $TP..."
                TDP="$DIST_PATH/ansible-playbook/$T"       
                cp_cmd="cp $TP $TDP"
                echo -e "       copying with cmd \"$cp_cmd\""
                eval $cp_cmd
                exit_code=$?
                if [[ "$exit_code" != "0" ]]; then
                    echo -e "     tool copy failed with code $exit_code"
                    exit $exit_code
                fi

                if head -n 1 $TDP | grep -q '^#!'; then
                    echo -e "     removing first line from $TDP"
                    sed -i 1d $TDP
                fi

                if [[ "$REMOVE_INCLUDED_TOOL_COMMENTS" == "1" ]]; then
                    echo -e "     removing comments from $TDP"
                    sed -i '/^[[:blank:]]*#/d;s/#.*//' $TDP
                fi

                chmod 755 $TDP

                echo -e " Finished tool $T => $TP => $TDP\n"
            done
            exit 0
        fi

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

#        >&2 echo "Executing Test Playbook with json_audit stdout callback"
#        ANSIBLE_JSON_AUDIT_LOG_FILE=$(mktemp)

#        ANSIBLE_ENVIRONMENT_NAME="test environment 123" \
#        ANSIBLE_JSON_LOG_PATH=$ANSIBLE_JSON_AUDIT_LOG_FILE \
#        ANSIBLE_DISPLAY_ARGS_TO_STDOUT=False \
#        ANSIBLE_STDOUT_CALLBACK=unixy \
#        ANSIBLE_CALLBACK_WHITELIST=json_audit \
#            testAnsible

#        ls -al $ANSIBLE_JSON_AUDIT_LOG_FILE
#        wc -l $ANSIBLE_JSON_AUDIT_LOG_FILE | grep -v "^0 "
#        grep -c '^{' $ANSIBLE_JSON_AUDIT_LOG_FILE|grep -v '^0$'
#        grep '^{' $ANSIBLE_JSON_AUDIT_LOG_FILE|head -n 5

        >&2 echo "Executing Test Playbook with codekipple_concise stdout callback"
        ANSIBLE_DISPLAY_ARGS_TO_STDOUT=False \
        ANSIBLE_STDOUT_CALLBACK=codekipple_concise \
            testAnsible

        >&2 echo "Executing Test Playbook with beautiful_output stdout callback"
        ANSIBLE_DISPLAY_ARGS_TO_STDOUT=False \
        ANSIBLE_STDOUT_CALLBACK=beautiful_output \
            testAnsible



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
		    ansible-playbook .METADATA.JSON .ANSIBLE-RELEASE.JSON $ANSIBLE_CONFIG_FILENAME
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
