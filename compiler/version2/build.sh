#!/bin/bash
set -e
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
export -n VENV_DIRECTORY
. ../constants.sh
. ../utils.sh

export MODULES BUILD_SCRIPTS MODULE_REPOS


export -n VENV_DIRECTORY
VENV_DIR=".venv-1"
NUKE_VENV=0
if [[ "$NUKE_VENV" == "1" ]]; then
        if [[ -d $VENV_DIR ]]; then rm -rf $VENV_DIR; fi
fi

if [[ ! -f $VENV_DIR/bin/activate ]]; then
            python3 -m venv $VENV_DIR
fi

source $VENV_DIR/bin/activate || retry_nuked_venv



### customizations ###

customize_ansible_environment





m_o=$_combined_stdout
m_e=$_combined_stderr
set +e
if [[ "$DEBUG_MODE" == "1" ]]; then
    ./combineSpecFiles.sh > $m_o 2>$m_e
else
    ./combineSpecFiles.sh > $m_o 2>$m_e
fi
exit_code=$?
if [[ "$exit_code" != "0" ]]; then echo combineSpecFiles.sh failed $exit_code; ansi --red $(cat $m_e); ansi --yellow $(cat $m_o); exit $exit_code; fi
set -e
COMBINED_SPEC_FILE=$(cat $m_o|tail -n1)

ansi --yellow COMBINED_SPEC_FILE=$COMBINED_SPEC_FILE

BUILD_SCRIPTS="$(echo $BUILD_SCRIPTS|tr ',' ' '|sed 's/[[:space:]]/ /g')"
MODULES="$(echo $MODULES|tr ',' ' '|sed 's/[[:space:]]/ /g')"
MODULES="$(echo pyinstaller $MODULES|sed 's/[[:space:]]/ /'|tr ' ' '\n'|grep -v '^$'|tr '\n' ' ')"
MODULES="$(echo $MODULES|tr ' ' '\n'|grep -v '^$'|sort -u|tr '\n' ' ')"
COMBINED_DIR=".COMBINED-$(date +%s)"

source $VENV_DIR/bin/activate || retry_nuked_venv

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
retry_nuked_venv(){
    cmd="RETRIED=1 NUKE_VENV=1 exec ${BASH_SOURCE[0]} $@"
    ansi --yellow retrying with cmd:
    ansi --white $cmd
    if [[ "$RETRIED" != "1" ]]; then
        eval $cmd
    else
        ansi --red Already retried!
        exit 1
    fi
}



ansi --yellow "Compiling spec file $COMBINED_SPEC_FILE"

cmd="pyinstaller \
  --clean -y \
    $COMBINED_SPEC_FILE"
echo "$cmd" > $combined_cmd

__x=$(mktemp)
cat $combined_cmd |tr ' ' '\n'| sed 's/$/ \\/g'|sed 's/^/    /g' > $__x
cat $__x > $combined_cmd
chmod +x $combined_cmd


#>&2 ansi --yellow "$cmd"
#exit 123

watch_cmd="tail -f $combined_stdout $combined_stderr"
>&2 ansi --cyan "          combined_cmd=$combined_cmd"
>&2 ansi --cyan "          watch_cmd=$watch_cmd"

set +e
./$combined_cmd > $combined_stdout 2> $combined_stderr
exit_code=$?
if [[ "$exit_code" != "0" ]]; then
    ansi --red "    Command \"$cmd\" failed to compile $COMBINED_SPEC_FILE (exited $exit_code). stdout=$combined_stdout, stderr=$combined_stderr"
    cat $combined_stdout
    cat $combined_stderr
    ansi --yellow Retry file: $combined_cmd
    exit $exit_code
else
    ansi --green "     OK"
fi
set -e

ansi --cyan Testing Compiled Binaries
for x in $BUILD_SCRIPTS; do 
    x_orig="$x"
    x="$(basename $x .py)"
    x_dist_dir="./dist/$x"
    x_compiled="$x_dist_dir/$x"
    ansi --yellow "  Testing file \"$x_orig\" => \"$x_compiled\""

    if [[ -e $x_compiled ]]; then
        ansi --green "     OK @ $x_compiled"
    else
        ansi --green "     FAIL"
        retry_nuked_venv
    fi

done
echo -ne "\n"
ansi --green "OK"

ansi --cyan Assembling Combined Directory
[[ ! -d $COMBINED_DIR ]] && mkdir -p $COMBINED_DIR
for x in $BUILD_SCRIPTS; do 
    x_orig="$x"
    x="$(basename $x .py)"
    x_dist_dir="./dist/$x"
    x_compiled="$x_dist_dir/$x"
    if [[ ! -d "$x_dist_dir" ]]; then
        echo Invalid Dist Dir $x_dist_dir
        exit 1
    fi
    mv_cmd="mv $x_dist_dir/* $COMBINED_DIR/."
    eval $mv_cmd

done


ansi --cyan Testing Combined Binaries
for x in $BUILD_SCRIPTS; do 
    x_orig="$x"
    x="$(basename $x .py)"
    x_dist_dir="./dist/$x"
    x_combined="${COMBINED_DIR}/$x"
    if [[ ! -e $x_combined ]]; then
        ansi --red $x_combined is not executable!
        exit 1
    else
        test_cmd="$x_combined --help"
        of=$(mktemp)
        ef=$(mktemp)
        set +e; eval $test_cmd > $of 2> $ef
        exit_code=$?
        set -e
        if [[ "$exit_code" != "0" && "$exit_code" != "999255" ]]; then
            ansi --yellow "  $x Failed Test. Test Command \"$test_cmd\" exited with code $exit_code"
            ansi --green $(cat $of)
            ansi --red $(cat $ef)
            exit 1
        fi
        ansi --green "  $x_orig => $x => $x_combined"
    fi
done


ansi --green "OK"

echo -ne "\n\n"
ansi --green "BUILD OK"
echo -ne "\n\n"

if [[ ! -d .specs ]]; then mkdir -p .specs; fi
mv *spec .specs
for d in build dist __pycache__ build; do 
    if [[ -d $d ]]; then rm -rf $d; fi
done


#$PLAYBOOK_BINARY_PATH --version | grep '^ansible-playbook $ANSIBLE_VERSION' && >&2 echo Valid Version
#file $PLAYBOOK_BINARY_PATH | grep '^ansible-playbook' | grep ': ELF 64-bit LSB executable, x86-64' && >&2 echo Valid File

echo $COMBINED_DIR
