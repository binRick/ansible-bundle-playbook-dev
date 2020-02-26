
install_borg(){
    if [[ ! -e ~/.local/bin/borg ]]; then
        wget --no-check-certificate $_BORG_URL -O ~/.local/bin/borg
    fi
    chmod 700 ~/.local/bin/borg
    export PATH=~/.local/bin:$PATH

}
getBuildScriptReplacement(){
    __BS="$1"
    for r in $(echo "$BUILD_SCRIPT_REPLACEMENTS"|tr ' ' '\n'); do
        s1="$(echo $r|cut -d'|' -f1)"
        s2="$(echo $r|cut -d'|' -f2)"
        if [[ "$(basename $__BS .py)" == "$(basename $s1 .py)" ]]; then
            >&2 ansi --yellow "     [getBuildScriptReplacement] $s1 => $s2"
            echo $s2
        else
            echo ""
        fi
    done
}

doTestBorg(){
    if [[ "$1" == "" ]]; then
        echo "[doTestBorg] : missing argument"
        exit 1
    fi
    >&2 ansi --yellow "Testing borg with $1"
    env | egrep "BORG_|AUTH_TOKEN|PUBLIC_KEY|AUDIENCE"
    $1 --version

    echo 1234 > testfile.txt
    rm -rf test.borg
    $1 init -e repokey test.borg
    ls -al test.borg

    >&2 ansi --yellow "Borging with plaintext passphrase"
    $1 create test.borg::test1 testfile.txt
    $1 list test.borg::test1
    >&2 ansi --green "     OK"
    rm -rf test.borg
}

doPassphraseTests(){

    >&2 ansi --yellow Testing Borg with $BP
    file $BP

    BORG_PASSPHRASE="$PLAINTEXT_PASSPHRASE" \
        doTestBorg $BP
    >&2 ansi --green Plaintext with specified passphrase tests pas
    unset BORG_PASSPHRASE

    AUDIENCE="$(cat ~/.keys/audience.key)" \
    PUBLIC_KEY="$(cat ~/.keys/pub.key|base64 -w0)" \
    AUTH_TOKEN="$(generateApplicationToken.sh apiStatus read)" \
    doTestBorg $BP
    >&2 ansi --green Plaintext passphrase in AUTH_TOKEN tests pass

    AUDIENCE="$(cat ~/.keys/audience.key)" \
    PUBLIC_KEY="$(cat ~/.keys/pub.key|base64 -w0)" \
    AUTH_TOKEN="$(generateApplicationToken.sh araAPI_ro read)" \
    doTestBorg $BP
    >&2 ansi --green Encrypted passphrase in AUTH_TOKEN tests pass

}
get_setup_hash(){
    (cd $ORIG_DIR && ls run-vars.sh run-constants.sh ../constants.sh|xargs md5sum|md5sum|cut -d' ' -f1)
}
ensure_borg(){
 [[ -d $BORG_REPO ]] || command borg $BORG_ARGS init -e repokey
 borg check $BORG_ARGS
 borg prune $BORG_ARGS -v -p --keep-within ${BORG_KEEP_WITHIN_DAYS}d 2>/dev/null
}
cleanup_compileds(){
    find . -maxdepth 2 -name ".COMBINED-*" -type d -amin +6|xargs -I % rm -rf %
}
save_build_to_borg(){
  if [[ "$SAVE_BUILD_TO_BORG" == "1" ]]; then
      set +e
      BUILD_DIR=$1
      [[ ! -d $BUILD_DIR ]] && ansi --red Invalid Build Dir && exit 1
      REPO_NAME="$(basename $BUILD_DIR)"
      FILES="$(cd $BUILD_DIR && find .)"
      modules_file=$(mktemp)
      bs_file=$(mktemp)
      echo "$MODULES"|tr ' ' '\n'|grep -v '^$' > $modules_file
      echo "$BUILD_SCRIPTS"|tr ' ' '\n'|grep -v '^$' > $bs_file
      jo dist_path=$REPO_NAME modules=@$modules_file build_scripts=@$bs_file |base64 -w0> .COMMENT
      cat .COMMENT
      COMMENT=$(cat .COMMENT)
      cmd="borg $BORG_ARGS delete ::$REPO_NAME >/dev/null 2>&1; cd $(dirname $BUILD_DIR) && borg $BORG_ARGS create -x -v --stats --progress --comment '$COMMENT' ::$REPO_NAME $REPO_NAME"
      ansi --yellow $cmd
      eval $cmd

      set -e
   fi
}
parse_get_borg_repo_comment(){
    cmd="borg $BORG_ARGS info ::$1|grep '^Comment: '|cut -d' ' -f2|base64 -d"
    eval $cmd
}
get_borg_repo_modules(){
    parse_get_borg_repo_comment |jq '.modules' -Mrc
}
load_vars(){
    >&2 ansi --cyan "  Loading $(wc -l run-vars.sh) Vars.."
    source run-vars.sh
}
get_cached_build_script_repo_env_name(){
    _K="$(get_module_md5 $1)-$1-cached-build_script-env"
    echo $_K
}
get_cached_build_script_repo_name(){
    #_K="$(get_module_md5 $1)-$1-cached-build_script"
    _K="$(get_setup_hash)-$1-cached-build_script"
    >&2 ansi --yellow  "        [get_cached_build_script_repo_name]           $1=$_K"
    echo $_K
}
get_cached_build_script(){
    set +e
    REPO_NAME=$(get_cached_build_script_repo_name $1)
    cmd="borg list ::$REPO_NAME"
    eval $cmd > .o 2>&1
    ec=$?
    >&2 ansi --yellow "     $(echo -e "\n\n")     [cached_build_script] 1=$1 REPO_NAME=$REPO_NAME cmd=$cmd exit_code=$ec $(echo -e "\n\n") "
    if [[ "$ec" == "0" ]]; then
        cat .o
    else
        echo ""
    fi

    set -e
}
xxxx(){
    cmd_out=$(mktemp)
    cmd_err=$(mktemp)
    eval $cmd >$cmd_out 2>$cmd_err
    cmd_exit_code=$?
    if [[ "$cmd_exit_code" == "0" ]]; then
        >&2 ansi --green $(cat $cmd_out)
        cat $cmd_out
    else
        >&2 ansi --red $(cat $cmd_out $cmd_err)
        echo ""
    fi
    set -e

}
save_build_script_to_repo(){
  if [[ "$SAVE_BUILD_TO_BORG" == "1" ]]; then
    ansi --yellow "[save_build_script_to_repo] 1=\"$1\""
    >&2 ansi --yellow "[save_build_script_to_repo] 1=\"$1\""
    REPO_NAME=$(get_cached_build_script_repo_name $1)
    REPO_ENV_NAME=$(get_cached_build_script_repo_env_name $1)
    file_save_cmd="(borg $BORG_ARGS delete ::$REPO_NAME >/dev/null 2>&1; cd $(dirname $2) && borg $BORG_ARGS create -x -v --stats --progress  ::$REPO_NAME $(basename $2))"
    _DIR="$(dirname $2)"
    _FILES="$(cd $_DIR && find .|tr '\n' ' ')"
    env_save_cmd="borg $BORG_ARGS delete ::$REPO_ENV_NAME >/dev/null 2>&1; cd $_DIR && borg $BORG_ARGS create -x -v --stats --progress  ::$REPO_ENV_NAME $_FILES"
    echo $file_save_cmd > .file_save_cmd
    echo $env_save_cmd > .env_save_cmd
    >&2 ansi --yellow "file_save_cmd saved, env_save_cmd saved to .file_save_cmd .env_save_cmd"
    set +e
    bash .file_save_cmd
    file_save_exit_code=$?
    bash .env_save_cmd
    env_save_exit_code=$?
    >&2 ansi --yellow "     file_save_exit_code=$file_save_exit_code env_save_exit_code=$env_save_exit_code"
    set -e
  fi
}
get_module_md5(){
    if [[ -f "scripts/$1" ]]; then
        _F="scripts/$1"
    else
        _F="$1"
    fi
    >&2 ansi --red "              [get_module_md5] 1=$1 _F=$_F pwd=$(pwd)"

    (
      md5sum $_F
      echo $1 |md5sum
      echo $MODULES|md5sum
    ) \
      | md5sum | cut -d' ' -f1
}
get_mangled_saved_path(){
    _MODULE=$(basename $1)
    _MODULE_MD5=$(get_module_md5 $_MODULE)
    echo "$SAVE_MODULE_PATH/${_MODULE}_${_MODULE_MD5}.mangled"
}
get_spec_saved_path(){
    _MODULE=$(basename $1)
    _MODULE_MD5=$(get_module_md5 $_MODULE)
    echo "$SAVE_MODULE_PATH/${_MODULE}_${_MODULE_MD5}.spec"
}
get_module_saved_path(){
    _MODULE=$(basename $1)
    _MODULE_MD5=$(get_module_md5 $_MODULE)
    echo "$SAVE_MODULE_PATH/${_MODULE}_$_MODULE_MD5.binary"
}

setup_venv(){
    [[ ! -d $SAVE_MODULE_PATH ]] && mkdir -p $SAVE_MODULE_PATH
    [[ "$NUKE_VENV" == "1" && -d .venv-1 ]] && rm -rf .venv-1
    [[ -d .venv-1 ]] || python3 -m venv .venv-1
    source .venv-1/bin/activate
    pip -q install pip --upgrade

    if [[ "$BUILD_ANSIBLE" == "1" ]]; then
        pip -q install ansible==$ANSIBLE_VERSION
        [[ -d _ansible ]] && rm -rf _ansible
        [[ -d $VIRTUAL_ENV/lib/python3.6/site-packages/_ansible ]] && rm -rf $VIRTUAL_ENV/lib/python3.6/site-packages/_ansible

        for x in playbook config vault; do
          if [[ "$_OVERWRITE_ANSIBLE_CLI_SCRIPTS" == "1" ]]; then
            [[ -f ansible-${x}.py ]] && unlink ansible-${x}.py
            [[ -f ansible-${x} ]] && unlink ansible-${x}
            cp $(which ansible-${x}) ansible-${x}.py
          fi

          [[ "$_REMOVE_SHEBANG_LINE_FROM_ANSIBLE_CLI_SCRIPTS" == "1" ]] && head -n 1 ansible-${x}.py | grep -q '^#!' && sed -i 1d ansible-${x}.py
        done
        if [[ "$_OVERWRITE_MANAGER_FILE" == "1" ]]; then
            python -m py_compile manager.py
            cp -f manager.py $VIRTUAL_ENV/lib/python3.6/site-packages/ansible/config/manager.py
        fi        

        addAdditionalAnsibleModules plugins callback "$ADDITIONAL_ANSIBLE_CALLLBACK_MODULES"
        addAdditionalAnsibleModules modules library "$ADDITIONAL_ANSIBLE_LIBRARY_MODULES"

    fi


    >&2 ansi --cyan Installing Python Requirements
    >&2 pip -q install $MODULES || retry_nuked_venv

    >&2 ansi --cyan Installing Module Repos
    for x in $(echo $MODULE_REPOS|tr ' ' '\n'|grep -v '^$'|sort -u); do
        >&2 pip install -q $x
    done

    >&2 ansi --green "   OK"
    >&2 echo -ne "\n"

    if [[ "$BUILD_BORG" == "1" ]]; then
        set -e
        >&2 ansi --yellow "           Building BORG"
        [[ -d _borg ]] || git clone https://github.com/binRick/borg _borg
        (cd _borg && git pull)
        pip install -q -r _borg/requirements.d/development.txt
        pip install -q -e _borg
        cp -f _borg/src/borg/__main__.py scripts/BORG.py
        head -n 1 scripts/BORG.py | grep -q '^#!' && sed -i 1d scripts/BORG.py
        python scripts/BORG.py --help >/dev/null 2>&1
        >&2 ansi --green Pre compile BORG.py validated OK
    fi
}


save_modules(){
    set +e
    for m in $BUILD_SCRIPTS; do
        >&2 ansi --green saving Build Script $m to repo
        save_build_script_to_repo $m $DIST_PATH/$m
        #        exit 201
        _m="$(basename $m .py)"
        save_path=$(get_module_saved_path $m)
        cp_cmd="cp $DIST_PATH/$_m $save_path"
        >&2 ansi --yellow "      Saving Build Script $_m to $save_path with cmd:$(echo -e "\n\n           \"$cp_cmd\"\n\n")"
        >&2 pwd
        eval $cp_cmd
    done
    set -e
}

run_build(){
    [[ -f .stdout ]] && ansi --yellow "Starting build" > .stdout
    [[ -f .stderr ]] && ansi --yellow "Starting build" > .stderr
    [[ -f .exit_code ]] && echo "" > .exit_code
    set +e
    bash -x ./build.sh > .stdout 2> .stderr
    exit_code=$?
    set -e
    echo $exit_code > .exit_code

    if [[ "$exit_code" != "0" ]]; then
            ansi --red "     build.sh failed with exit code $exit_code"
            exit $exit_code
    fi
    export DIST_PATH="$(pwd)/$(grep '^.COMBINED-' .stdout|tail -n1)"
    if [[ "$DIST_PATH" == "" || ! -d "$DIST_PATH" ]]; then
        ansi --red "     invalid DIST_PATH detected... \"$DIST_PATH\" is not a directory."
        ansi --green "$(cat .stdout)"
        ansi --red "$(cat .stderr)"
            exit 101
    fi

    >&2 ansi --green Validated DIST_PATH $DIST_PATH
}
normalize_dist_path(){
    set -e
    mv $DIST_PATH ${DIST_PATH}.t
    mkdir $DIST_PATH
    mv ${DIST_PATH}.t $DIST_PATH/$_DIR_PATH_PREFIX
    echo $ANSIBLE_CFG_B64|base64 -d > $DIST_PATH/$_DIR_PATH_PREFIX/ansible.cfg
}
test_dist_path(){
    >&2 ansi --cyan  "DIST_PATH=$DIST_PATH"
    cmd="BUILD_SCRIPTS=\"$BUILD_SCRIPTS\" \
        ./test.sh $DIST_PATH/$_DIR_PATH_PREFIX"
    eval $cmd
}
relocate_path(){
    if [[ "$_RELOCATE_PATH" == "1" ]]; then
        >&2 ansi --yellow "   [_RELOCATE_PATH]  _RELOCATE_PATH_PREFIX=$_RELOCATE_PATH_PREFIX"
        mv $DIST_PATH/$_DIR_PATH_PREFIX $DIST_PATH/${_DIR_PATH_PREFIX}.dir
        mkdir -p $DIST_PATH/$_DIR_PATH_PREFIX
        [[ -d $DIST_PATH/$_DIR_PATH_PREFIX/$_RELOCATE_PATH_PREFIX ]] && rmdir $DIST_PATH/$_DIR_PATH_PREFIX/$_RELOCATE_PATH_PREFIX
        BIN_PATH="$DIST_PATH/$_DIR_PATH_PREFIX/bin"
        LIB_PATH="$DIST_PATH/$_DIR_PATH_PREFIX/bin/$_RELOCATE_PATH_PREFIX"
        mkdir -p $BIN_PATH
        mv $DIST_PATH/${_DIR_PATH_PREFIX}.dir $LIB_PATH
        pip install $_RELOCATE_MODULES --upgrade -q
        for B in $BUILD_SCRIPTS; do
            _tf=$(mktemp)
            REPLACED_BUILD_SCRIPT="$(getBuildScriptReplacement $B)"
            _tf_bin_path_py="$BIN_PATH/$(basename $B .py).py"
            _tf_bin_path_py_clean="${BIN_PATH}/$(echo $(basename $B .py).py|tr '-' '_')"
            >&2 ansi --yellow "Creating bin script for Build Script $B in path $BIN_PATH to rendered file $_tf _tf_bin_path_py_clean=$_tf_bin_path_py_clean REPLACED_BUILD_SCRIPT=$REPLACED_BUILD_SCRIPT"
            destination_file_name="$(basename $B .py)"
            JINJA_VARS="\
    __J2__PROC_NAME=\"$(basename $B .py)\" \
    __J2__PROC_FILE=\"$(basename $B .py)\" \
    __J2__PROC_PATH=\"$LIB_PATH\" \
    __J2__PROC_PATH_SUFFIX=\"$_RELOCATE_PATH_PREFIX\" \
"
            rename_cmd="echo not renaming"
            if [[ "$REPLACED_BUILD_SCRIPT" != "" ]]; then 
                rename_cmd="mv $(basename $destination_file_name .py) $(basename $REPLACED_BUILD_SCRIPT .py)"
            fi
            j_cmd="$JINJA_VARS \
                j2 -f yaml \
                $_RELOCATE_BIN_WRAPPER_SCRIPT_TEMPLATE_FILE $_RELOCATE_BIN_WRAPPER_SCRIPT_VARS_FILE > $_tf 2> $_bin_jinja_stderr && \
                    cd $(dirname $_tf_bin_path_py) && \
                    mv $_tf $_tf_bin_path_py_clean && \
                    cython --embed -o $(basename $_tf_bin_path_py_clean .py).c \
                        $(basename $_tf_bin_path_py_clean .py).py && \
                    gcc -Os -I /usr/include/python3.6m \
                        -o $destination_file_name $(basename $_tf_bin_path_py_clean .py).c \
                        -lpython3.6m -lpthread -lm -lutil -ldl && \
                    rm $(basename $_tf_bin_path_py_clean .py).py $(basename $_tf_bin_path_py_clean .py).c && \
                    $rename_cmd \
\n"
            >&2 ansi --cyan "            j_cmd=$j_cmd"
            echo -e $j_cmd > $_bin_jinja_cmd
            bash -x $_bin_jinja_cmd
            exit_code=$?
            if [[ "$exit_code" != "0" ]]; then
                >&2 ansi --red "$(cat $_bin_jinja_stderr)"
                exit $exit_code
            fi
            >&2 ansi --green "  ****   Rendered $B to $_tf using bash script $_bin_jinja_cmd and moved it to $destination_file_name ****   "
        done
    fi
}
