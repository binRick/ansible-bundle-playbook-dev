#!/bin/bash
set -e
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source ~/.ansi
export -n VENV_DIRECTORY

[[ "$BUILD_SCRIPTS" == "" ]] && \
    export BUILD_SCRIPTS="test.py test1.py"

COMBINED_DIR=".COMBINED-$(date +%s)"
VENV_DIR=".venv-1"
NUKE_VENV=0
MANGLE_SCRIPT="./mangleSpec.sh"
combined_stdout=.combined-compile.stdout
combined_stderr=.combined-compile.stderr
MODULES="pyinstaller $MODULES"
#setproctitle pyaml psutil paramiko"

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

ansi --cyan Installing Python Requirements
pip -q install $MODULES || retry_nuked_venv

ansi --green "   OK"

echo -ne "\n"

get_mangle_vars_file(){
    x="$(basename $1 .py)"
    x_mangle_vars=".${x}_mangled_vars.txt"
    echo $x_mangle_vars
}

ansi --cyan Processing Python Scripts
for x in $BUILD_SCRIPTS; do 
    DO_COMPILE=0
    DO_MANGLE=1
    x_orig="$x"
    x="$(basename $x .py)"
    x_spec="${x}.spec"
    x_mangle_vars="$(get_mangle_vars_file $x_orig)"
    mangle_cmd="$MANGLE_SCRIPT $x_spec"
    ansi --yellow "  Creating Spec from file \"$x_orig\""

    pyi-makespec \
        --hidden-import="paramiko" \
        --hidden-import="pyaml" \
        --hidden-import="psutil" \
        -p $VENV_DIR/lib64/python3.6/site-packages \
           ${x}.py > .${x}-makespec.stdout 2> .${x}-makespec.stderr || retry_nuked_venv
    exit_code=$?
    ansi --green "     OK"


    if [[ "$DO_COMPILE" == "1" ]]; then
        ansi --yellow "  Compiling file \"$x_orig\" using spec file $x_spec"
        pyinstaller \
            --clean -y \
                $x_spec > .${x}-compile.stdout 2> .${x}-compile.stderr || retry_nuked_venv
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
#        ansi --green "   Added block Cipher!"
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
merge_line="MERGE( (test_a, 'test', 'test'), (test1_a, 'test1', 'test1') )"
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

#cat $COMBINED_SPEC_FILE
#exit

ansi --yellow "Compiling spec file $COMBINED_SPEC_FILE"

cmd="pyinstaller \
  --clean -y \
    $COMBINED_SPEC_FILE"

set +e && eval $cmd > $combined_stdout 2> $combined_stderr
exit_code=$?
set -e
if [[ "$exit_code" != "0" ]]; then
    ansi --red "    Command \"$cmd\" failed to compile $COMBINED_SPEC_FILE (exited $exit_code). stdout=$combined_stdout, stderr=$combined_stderr"
    cat $combined_stdout
    cat $combined_stderr
    exit $exit_code
else
    ansi --green "     OK"

fi

#cat $COMBINED_SPEC_FILE
#exit


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
        test_cmd="$x_combined --test"
        of=$(mktemp)
        ef=$(mktemp)
        set +e; eval $test_cmd > $of 2> $ef
        exit_code=$?
        set -e
        if [[ "$exit_code" != "0" ]]; then
            ansi --red "  $x Failed Test. Test Command \"$test_cmd\" exited with code $exit_code"
            exit 1
        fi
        ansi --green "  $x_orig => $x => $x_combined"
    fi
done


ansi --green "OK"

#find $COMBINED_DIR
#ls -al $COMBINED_DIR

echo -ne "\n\n"
ansi --green "BUILD OK"
echo -ne "\n\n"

if [[ ! -d .specs ]]; then mkdir -p .specs; fi
mv *spec .specs
for d in build dist __pycache__ build; do 
    if [[ -d $d ]]; then rm -rf $d; fi
done

echo $COMBINED_DIR
