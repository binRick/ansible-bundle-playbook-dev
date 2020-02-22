#!/bin/bash
set -e
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
export -n VENV_DIRECTORY
. ../constants.sh
. ../utils.sh

[[ "$MODULES" == "" ]] && \
    export MODULES="paramiko ansible json2yaml"

[[ "$BUILD_SCRIPTS" == "" ]] && \
    export BUILD_SCRIPTS="test.py test1.py"

BUILD_SCRIPTS="$(echo $BUILD_SCRIPTS|tr ',' ' '|sed 's/[[:space:]]/ /g')"
MODULES="$(echo $MODULES|tr ',' ' '|sed 's/[[:space:]]/ /g')"

COMBINED_DIR=".COMBINED-$(date +%s)"
VENV_DIR=".venv-1"
NUKE_VENV=0
MANGLE_SCRIPT="./mangleSpec.sh"
combined_stdout=.combined-compile.stdout
combined_stderr=.combined-compile.stderr
MODULES="$(echo pyinstaller $MODULES|sed 's/[[:space:]]/ /'|tr ' ' '\n'|grep -v '^$'|tr '\n' ' ')"
MODULES="$(echo $MODULES|tr ' ' '\n'|grep -v '^$'|sort -u|tr '\n' ' ')"


retry_nuked_venv(){
    cmd="RETRIED=1 NUKE_VENV=1 exec ${BASH_SOURCE[0]} $@"
    ansi --yellow retrying with cmd:
    ansi --white $cmd
    if [[ "$RETRIED" != "1" ]]; then
        eval $cmd
    else
        >&2 ansi --red "Already retried.."
        exit 998
    fi
}

if [[ "$NUKE_VENV" == "1" ]]; then
    if [[ -d $VENV_DIR ]]; then rm -rf $VENV_DIR; fi
fi

for d in build dist __pycache__ $COMBINED_DIR; do 
    if [[ -d $d ]]; then rm -rf $d; fi
done

if [[ ! -f $VENV_DIR/bin/activate ]]; then
    python3 -m venv $VENV_DIR
fi

source $VENV_DIR/bin/activate || retry_nuked_venv

>&2 ansi --cyan Installing Python Requirements
>&2 pip -q install $MODULES || retry_nuked_venv

>&2 ansi --cyan Installing Module Repos
for x in $(echo $MODULE_REPOS|tr ' ' '\n'|grep -v '^$'|sort -u); do
    >&2 pip install -q $x
done

>&2 ansi --green "   OK"

>&2 echo -ne "\n"

get_mangle_vars_file(){
    x="$(basename $1 .py)"
    x_mangle_vars=".${x}_mangled_vars.txt"
    echo $x_mangle_vars
}

ansi --cyan Processing Python Scripts
for x in $BUILD_SCRIPTS; do 
    _BS="$x"
    DO_MANGLE=1
    x_orig="$x"
    _BS_ORIG="$x"
    x="$(basename $x .py)"
    _BS="$x"
    x_spec="${_BS}.spec"
    x_mangle_vars="$(get_mangle_vars_file $x_orig)"
    mangle_cmd="$MANGLE_SCRIPT $x_spec"
    ansi --yellow "  Creating Spec from file \"$x_orig\""

    gm_o=$(mktemp)
    gm_e=$(mktemp)
    getModules >$gm_o 2>$gm_e

    >&2 ansi --yellow $gm_e
    >&2 ansi --green $gm_o
#    exit 100


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

    echo -e "\n\n$gm_o $gm_e\n\n"

    >&2 ansi --green "     $(wc -l $gm_o) Hidden Imports"
    cmd="pyi-makespec \
            $(findAllVenvModules|mangleModules|tr '\n' ' ') \
            $_ADD_DATAS \
        -p $VIRTUAL_ENV/lib64/python3.6/site-packages \
           ${_BS}.py > $spec_combined_stdout_mkspec 2> $spec_combined_stderr_mkspec"
    echo "$cmd" > $spec_combined_cmd
    __x=$(mktemp)
    cat $spec_combined_cmd |tr ' ' '\n'| sed 's/$/ \\/g'|sed 's/^/    /g' > $__x
    cat $__x > $spec_combined_cmd


    chmod +x $spec_combined_cmd
    >&2 ansi --yellow "spec_combined_cmd=$spec_combined_cmd"
    >&2 ansi --yellow "spec_combined_stdout_mkspec=$spec_combined_stdout_mkspec"
    >&2 ansi --yellow "spec_combined_stderr_mkspec=$spec_combined_stderr_mkspec"
#    exit 666
    ./$spec_combined_cmd 2> .${_BS}-makespec.stderr
    exit_code=$?
    if [[ "$exit_code" != "0" ]]; then cat ${_BS}-makespec.stderr; >&2 ansi --red "pyi-makespec failed"; exit $exit_code; fi
    ansi --green "     OK"


    if [[ "$DO_MANGLE" == "1" ]]; then
        ansi --yellow "  Mangling file \"$x_orig\" using spec file $x_spec with cmd \"$mangle_cmd\""
        mangle_stdout=$(mktemp)
        mangle_stderr=$(mktemp)
        eval $mangle_cmd > $mangle_stdout 2>$mangle_stderr
        exit_code=$?
        if [[ "$exit_code" != "0" ]]; then
            >&2 ansi --red "    Command \"$mangle_cmd\" failed to mangle $x_orig (exited $exit_code). stdout=$mangle_stdout, stderr=$mangle_stderr"
            exit $exit_code
        else
            cp $mangle_stdout $x_mangle_vars
            ansi --green "    OK - $x_mangle_vars"
        fi
    else
        ansi --red Undefined behavior
        exit 999
    fi
done 

get_mangled_var(){
    (source $1 && echo ${!2})
}

echo -ne "\n"
ansi --cyan Create Compined Spec File
COMBINED_SPEC_FILE=""
for x in $BUILD_SCRIPTS; do 
    x="$(basename $x .py)"
    COMBINED_SPEC_FILE="${COMBINED_SPEC_FILE}_${x}"
done

COMBINED_SPEC_FILE="${COMBINED_SPEC_FILE}.spec"
COMBINED_SPEC_FILE="$(echo $COMBINED_SPEC_FILE | sed 's/^_//g')"

[[ -f $COMBINED_SPEC_FILE ]] && rm $COMBINED_SPEC_FILE
touch $COMBINED_SPEC_FILE
ansi --green "OK - $COMBINED_SPEC_FILE"

echo -ne "\n"

ansi --cyan Assembling combined spec file from mangled spec files

ansi --magenta " [Block Cipher]"
for x in $BUILD_SCRIPTS; do 
    x_orig="$x"
    x="$(basename $x .py)"
    x_spec="${x}.spec"
    mangle_cmd="$MANGLE_SCRIPT $x_spec"
    x_mangle_vars="$(get_mangle_vars_file $x_orig)"
    PYZ_file="$(get_mangled_var $x_mangle_vars PYZ)"
    EXE_file="$(get_mangled_var $x_mangle_vars EXE)"

    if ! grep -q '^block_cipher' $COMBINED_SPEC_FILE; then
        cat "$(get_mangled_var $x_mangle_vars BLOCK_CIPHER)" >> $COMBINED_SPEC_FILE
        >&2 ansi --cyan "    Added Block Cipher to combined spec file"
    fi
done 
ansi --green " OK"

echo -ne "\n\n" >> $COMBINED_SPEC_FILE
for x in $BUILD_SCRIPTS; do 
    x_orig="$x"
    x="$(basename $x .py)"
    x_spec="${x}.spec"
    x_mangle_vars="$(get_mangle_vars_file $x_orig)"
    for k in ANALYSIS; do 
#        ansi --magenta " [$x_orig => $k]"
        cat "$(get_mangled_var $x_mangle_vars $k)" >> $COMBINED_SPEC_FILE
        echo -ne "\n" >> $COMBINED_SPEC_FILE
#        ansi --green "   OK"
    done
    echo -ne "\n\n" >> $COMBINED_SPEC_FILE
done
echo -ne "\n\n" >> $COMBINED_SPEC_FILE

ansi --magenta " [Merge Statement]"
echo -ne "\n" >> $COMBINED_SPEC_FILE
merge_line="MERGE("
for x in $BUILD_SCRIPTS; do 
    x="$(basename $x .py)"
    script_line=" (${x}_a, '$x', '$x'),"
    merge_line="${merge_line}${script_line}"
done

merge_line="$(echo $merge_line|sed 's/,$//g')"
merge_line="${merge_line} )"
echo $merge_line >> $COMBINED_SPEC_FILE
echo -ne "\n\n" >> $COMBINED_SPEC_FILE


echo -ne "\n\n" >> $COMBINED_SPEC_FILE
for x in $BUILD_SCRIPTS; do 
    x_orig="$x"
    x="$(basename $x .py)"
    x_spec="${x}.spec"
    x_mangle_vars="$(get_mangle_vars_file $x_orig)"
    for k in PYZ EXE COLLECT; do 
        >&2 ansi --magenta " [$k]"
        cat "$(get_mangled_var $x_mangle_vars $k)" >> $COMBINED_SPEC_FILE
        echo -ne "\n" >> $COMBINED_SPEC_FILE
        >&2 ansi --green "   OK"
    done
    echo -ne "\n\n" >> $COMBINED_SPEC_FILE
done
echo -ne "\n\n" >> $COMBINED_SPEC_FILE


for x in $BUILD_SCRIPTS; do 
    x="$(basename $x .py)"
    cmd="sed -i \"s/^$x/$(echo $x|tr '-' '_')/g\" $COMBINED_SPEC_FILE"
    eval $cmd
    cmd="sed -i \"s/${x}_/$(echo $x|tr '-' '_')_/g\" $COMBINED_SPEC_FILE"
    eval $cmd
done

echo $COMBINED_SPEC_FILE
exit 0
