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
# $(getVenvModules|tr '\n' ' ')"
MODULES="$(echo $MODULES|tr ' ' '\n'|grep -v '^$'|sort -u|tr '\n' ' ')"


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
    DO_COMPILE=0
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

    echo -e "\n\n$gm_o $gm_e\n\n"

    HIDDEN_IMPORT_LINES="$(cat $gm_o|grep 'hidden-import=')"

    >&2 ansi --green "     $(wc -l $gm_o) Hidden Imports"
    cmd="pyi-makespec \
        -p $VENV_DIR/lib64/python3.6/site-packages \
           ${_BS}.py > .${_BS}-makespec.stdout"
    eval $cmd 2> .${_BS}-makespec.stderr # || retry_nuked_venv
    exit_code=$?
    if [[ "$exit_code" != "0" ]]; then cat ${_BS}-makespec.stderr; exit $exit_code; fi
    ansi --green "     OK"


    if [[ "$DO_COMPILE" == "1" ]]; then
        ansi --yellow "  Compiling file \"$x_orig\" using spec file $x_spec"
        pyinstaller \
        $HIDDEN_IMPORT_LINES \
            --clean -y \
                $x_spec > .${_BS}-compile.stdout 2> .${_BS}-compile.stderr || retry_nuked_venv
        exit_code=$?

        ansi --green "     OK"
    elif [[ "$DO_MANGLE" == "1" ]]; then
        ansi --yellow "  Mangling file \"$x_orig\" using spec file $x_spec with cmd \"$mangle_cmd\""
        mangle_stdout=$(mktemp)
        mangle_stderr=$(mktemp)
        eval $mangle_cmd > $mangle_stdout 2>$mangle_stderr
        exit_code=$?
        if [[ "$exit_code" != "0" ]]; then
            ansi --red "    Command \"$mangle_cmd\" failed to mangle $x_orig (exited $exit_code). stdout=$mangle_stdout, stderr=$mangle_stderr"
            exit $exit_code
        else
            cp $mangle_stdout $x_mangle_vars
            ansi --green "    OK - $x_mangle_vars"
        fi
    else
        ansi --red Undefined behavior
        exit 1
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


#cat $COMBINED_SPEC_FILE
#exit

echo -ne "\n\n" >> $COMBINED_SPEC_FILE
for x in $BUILD_SCRIPTS; do 
    x_orig="$x"
    x="$(basename $x .py)"
    x_spec="${x}.spec"
    x_mangle_vars="$(get_mangle_vars_file $x_orig)"
    for k in PYZ EXE COLLECT; do 
#        ansi --magenta " [$k]"
        cat "$(get_mangled_var $x_mangle_vars $k)" >> $COMBINED_SPEC_FILE
        echo -ne "\n" >> $COMBINED_SPEC_FILE
#        ansi --green "   OK"
    done
    echo -ne "\n\n" >> $COMBINED_SPEC_FILE
done
echo -ne "\n\n" >> $COMBINED_SPEC_FILE

#cat $COMBINED_SPEC_FILE
#exit

if [[ "x" == "y" ]]; then
    ansi --magenta " [Analysis]"
    for x in $BUILD_SCRIPTS; do 
        x_orig="$x"
        x="$(basename $x .py)"
        x_spec="${x}.spec"
        mangle_cmd="$MANGLE_SCRIPT $x_spec"
        x_mangle_vars="$(get_mangle_vars_file $x_orig)"
        PYZ_file="$(get_mangled_var $x_mangle_vars PYZ)"
        EXE_file="$(get_mangled_var $x_mangle_vars EXE)"

        cat "$(get_mangled_var $x_mangle_vars ANALYSIS)" >> $COMBINED_SPEC_FILE
            ansi --green "   OK"
    done 
    ansi --green " OK"
fi

echo $COMBINED_SPEC_FILE
exit 0
