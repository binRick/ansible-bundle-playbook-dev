#!/bin/bash
set -e
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
. /etc/.ansi
. ../constants.sh
. ../utils.sh
. run-constants.sh
. run-utils.sh

[[ "$MODULES" == "" ]] && \
    export MODULES="paramiko ansible json2yaml"

[[ "$BUILD_SCRIPTS" == "" ]] && \
    export BUILD_SCRIPTS="test.py test1.py"

BUILD_SCRIPTS="$(echo $BUILD_SCRIPTS|tr ',' ' '|sed 's/[[:space:]]/ /g')"
MODULES="$(echo $MODULES|tr ',' ' '|sed 's/[[:space:]]/ /g')"
COMBINED_DIR=".COMBINED-$(date +%s)"
MANGLE_SCRIPT="./mangleSpec.sh"
combined_stdout=~/.combined-compile.stdout
combined_stderr=~/.combined-compile.stderr
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

for d in build dist __pycache__ $COMBINED_DIR; do 
    if [[ -d $d ]]; then rm -rf $d; fi
done


if [[ "$BUILD_ANSIBLE" == "1" ]]; then
    export _ADD_DATAS="\
                        --add-data $VIRTUAL_ENV/lib/python3.6/site-packages/${_ADD_DATA_ANSIBLE_PATH}/config/base.yml:${_DATA_PREFIX}/config \
                        --add-data $VIRTUAL_ENV/lib/python3.6/site-packages/${_ADD_DATA_ANSIBLE_PATH}/config/module_defaults.yml:${_DATA_PREFIX}/config \
                        --add-data $VIRTUAL_ENV/lib/python3.6/site-packages/${_ADD_DATA_ANSIBLE_PATH}/utils/shlex.py:${_DATA_PREFIX}/utils \
                        --add-data $VIRTUAL_ENV/lib/python3.6/site-packages/${_ADD_DATA_ANSIBLE_PATH}/plugins/cache:${_DATA_PREFIX}/plugins/cache \
                        --add-data $VIRTUAL_ENV/lib/python3.6/site-packages/${_ADD_DATA_ANSIBLE_PATH}/module_utils:${_DATA_PREFIX}/module_utils \
                        --add-data $VIRTUAL_ENV/lib/python3.6/site-packages/${_ADD_DATA_ANSIBLE_PATH}/plugins/inventory:${_DATA_PREFIX}/plugins/inventory \
                        --add-data $VIRTUAL_ENV/lib/python3.6/site-packages/${_ADD_DATA_ANSIBLE_PATH}/plugins:${_DATA_PREFIX}/plugins \
                        --add-data $VIRTUAL_ENV/lib/python3.6/site-packages/${_ADD_DATA_ANSIBLE_PATH}/modules:${_DATA_PREFIX}/modules \
                        --add-data $VIRTUAL_ENV/lib/python3.6/site-packages/${_ADD_DATA_ANSIBLE_PATH}/executor/discovery/python_target.py:${_DATA_PREFIX}/executor/discovery \
"
else
    export _ADD_DATAS=""
fi


ansi --cyan Processing Python Scripts
for x in $BUILD_SCRIPTS; do 
    _BS="$x"
    DO_MANGLE=1
    x_orig="$x"
    _BS_ORIG="$x"
    x="$(basename $x .py)"
    _BS="$x"
    x_spec="${_BS}.spec"
    x_mangle_vars="$(get_mangle_vars_file $_BS_ORIG)"
    spec_saved_path="$(get_spec_saved_path $_BS_ORIG)"
    mangled_saved_path="$(get_mangled_saved_path $_BS_ORIG)"
    mangle_cmd="$MANGLE_SCRIPT $x_spec"
    save_path=$(get_module_saved_path $_BS_ORIG)
    cached_module_dir=$(get_cached_module_dir $_BS_ORIG)
    ansi --cyan "     Checking if Build Script $x exists in cache => $save_path=$save_path => spec_saved_path=$spec_saved_path :: mangled_saved_path=$mangled_saved_path"
    cache_build_script_repo_name=$(get_cached_build_script_repo_name $_BS_ORIG)
    _cached_build_script=$(get_cached_build_script $_BS_ORIG 2>/dev/null)
    ansi --yellow cache_build_script_repo_name=$cache_build_script_repo_name
    ansi --yellow _cached_build_script=$_cached_build_script

    set +e
    cached_build_script="$(echo -e "$_cached_build_script"|head -n1)"
    cached_build_mangled_vars_file="$(echo -e "$_cached_build_script"|head -n2|tail -n1)"
    if [[ "$cached_build_script" == "xxxxxxxxxxxxxx" ]]; then #&& -f "$cached_build_script" && -f "$cached_build_mangled_vars_file" ]]; then 
    #if [[ -f "$cached_build_script" && -f "$cached_build_mangled_vars_file" ]]; then 
           >&2 ansi --green "VALID CACHED BUILD \"$(echo $cached_build_script)\""
           >&2 ansi --green  "         cached_build_script=$cached_build_script cached_build_mangled_vars_file=$cached_build_mangled_vars_file"
           cp_cmd="(cd $ORIG_DIR && cp $CP_OPTIONS $cached_build_script $x_mangle_vars && cp $CP_OPTIONS $cached_build_mangled_vars_file .specs/$x_spec)"
           ansi --green "     Found Cached Files cp_cmd=$cp_cmd"
           eval $cp_cmd
    else
        ansi --yellow "  Creating Spec from file \"$x_orig\""

        gm_o=$(mktemp)
        gm_e=$(mktemp)
        getModules >$gm_o 2>$gm_e

        >&2 ansi --green "     $(wc -l $gm_o) Hidden Imports"
        if [[ -f scripts/${_BS}.py ]]; then
            _BS_PREFIX=scripts/
        fi                
        cmd="pyi-makespec \
                $(findBorgModules|mangleModules|tr '\n' ' ') \
                $(findAllVenvModules|mangleModules|tr '\n' ' ') \
                $(echo -e "$(echo $_ADDITIONAL_HIDDEN_MODULES|tr ' ' '\n')"|mangleModules|tr '\n' ' ') \
                $_ADD_DATAS \
            -p $VIRTUAL_ENV/lib64/python3.6/site-packages \
            --runtime-hook=hook-file1.py \
            -p _borg \
            -p _ansible \
               ${_BS_PREFIX}${_BS}.py > $spec_combined_stdout_mkspec 2> $spec_combined_stderr_mkspec"


        echo "$cmd" > $spec_combined_cmd
#        echo $spec_combined_cmd
#        exit 666

        __x=$(mktemp)
        cat $spec_combined_cmd |tr ' ' '\n'| sed 's/$/ \\/g'|sed 's/^/    /g' > $__x
        cat $__x > $spec_combined_cmd


        chmod +x $spec_combined_cmd
        >&2 ansi --yellow "spec_combined_cmd=$spec_combined_cmd"
        >&2 ansi --yellow "spec_combined_stdout_mkspec=$spec_combined_stdout_mkspec"
        >&2 ansi --yellow "spec_combined_stderr_mkspec=$spec_combined_stderr_mkspec"
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
                cp_cmd="cp $x_mangle_vars $mangled_saved_path && cp $x_spec $spec_saved_path"
                ansi --green "    OK - $x_mangle_vars => cp_cmd=$cp_cmd"
                eval $cp_cmd
            fi
        else
            ansi --red Undefined behavior
            exit 999
        fi
    fi
done 

echo -ne "\n"
ansi --cyan Create Combined Spec File
COMBINED_SPEC_FILE=""
for x in $BUILD_SCRIPTS; do 
    x="$(basename $x .py)"
    COMBINED_SPEC_FILE="${COMBINED_SPEC_FILE}_${x}"
done

COMBINED_SPEC_FILE="${COMBINED_SPEC_FILE}.spec"
COMBINED_SPEC_FILE="$(echo $COMBINED_SPEC_FILE | sed 's/^_//g')"

[[ -f $COMBINED_SPEC_FILE ]] && echo "" > $COMBINED_SPEC_FILE
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
    if [[ "$VALID_CACHED_BUILD_SCRIPT" == "1" ]]; then
        >&2 ansi --cyan "       VALID_CACHED_BUILD_SCRIPT $x"
        exit 201
    else
        x_orig="$x"
        x="$(basename $x .py)"
        x_spec="${x}.spec"
        x_mangle_vars="$(get_mangle_vars_file $x_orig)"
        for k in ANALYSIS; do 
            cat "$(get_mangled_var $x_mangle_vars $k)" >> $COMBINED_SPEC_FILE
            echo -ne "\n" >> $COMBINED_SPEC_FILE
        done
        echo -ne "\n\n" >> $COMBINED_SPEC_FILE
    fi
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
