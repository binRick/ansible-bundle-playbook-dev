
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
    if [[ "$BUILD_BORG" == "1" ]]; then
      (
        set -e
        if [[ "$1" == "" ]]; then
            echo "[doTestBorg] : missing argument"
            exit 1
        fi
        >&2 ansi --yellow "Testing borg with $1"
#        >&2 env | egrep "BORG_|AUTH_TOKEN|PUBLIC_KEY|AUDIENCE"
        >&2 $1 --version

        _TEST_FILE=$(mktemp)
        echo 1234 > $_TEST_FILE
        _BORG_REPO=/tmp/test.borg
        [[ -d $_BORG_REPO ]] && rm -rf $_BORG_REPO
        >&2 $1 init -e repokey $_BORG_REPO
        >&2 ls -al $_BORG_REPO

        >&2 ansi --yellow "Borging with plaintext passphrase"
        >&2 $1 create $_BORG_REPO::test1 $_TEST_FILE
        #>&2 $1 list $_BORG_REPO::test1 | grep $(basename $_TEST_FILE)
        [[ -d $_BORG_REPO ]] && rm -rf $_BORG_REPO
        >&2 ansi --green "     OK"
        echo "OK"
      )
    fi
}

doPassphraseTests(){
  (
    BP="$1"
    >&2 ansi --yellow Testing Borg with $BP
    >&2 file $BP

    BORG_PASSPHRASE="$PLAINTEXT_PASSPHRASE" \
        doTestBorg $BP
    >&2 ansi --green Plaintext with specified passphrase tests pass
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
  )
}
get_setup_hash(){
    (cd $ORIG_DIR && ls run-vars.sh run-constants.sh ../constants.sh|xargs md5sum|md5sum|cut -d' ' -f1)
}
ensure_borg(){
 [[ -d $BORG_REPO ]] || command borg $BORG_ARGS init -e repokey
# [[ "$CHECK_BORG" == "1" ]] && borg check $BORG_ARGS
# [[ "$PRUNE_BORG" == "1" ]] && borg prune $BORG_ARGS -v -p --keep-within ${BORG_KEEP_WITHIN_DAYS}d 2>/dev/null
}
cleanup_compileds(){
    find . -maxdepth 2 -name ".COMBINED-*" -type d -amin +6|xargs -I % rm -rf %
}
save_build_to_borg(){
  if [[ "$SAVE_BUILD_TO_BORG" == "1" ]]; then
      set +e
      BUILD_DIR="$1"
      [[ ! -d $BUILD_DIR ]] && ansi --red Invalid Build Dir && exit 1
      ___REPO_NAME="$(basename $BUILD_DIR)"

      for m in $BUILD_SCRIPTS; do
        _BIN_PATH="$BUILD_DIR/$(basename $m .py)"
        >&2 ansi --yellow "   _BIN_PATH=$_BIN_PATH m=$m REPO_NAME=$___REPO_NAME BUILD_DIR=$BUILD_DIR"
        save_binary_to_borg "$_BIN_PATH"
      done

      FILES="$(cd $BUILD_DIR && find .)"
      modules_file=$(mktemp)
      bs_file=$(mktemp)
      set +e
      echo "$MODULES"|tr ' ' '\n'|grep -v '^$' > $modules_file
      echo "$BUILD_SCRIPTS"|tr ' ' '\n'|grep -v '^$' > $bs_file
      set -e
      jo dist_path=$___REPO_NAME modules=@$modules_file build_scripts=@$bs_file |base64 -w0> .COMMENT
      cat .COMMENT
      COMMENT=$(cat .COMMENT)
      cmd="borg $BORG_ARGS delete ::$___REPO_NAME >/dev/null 2>&1; cd $BUILD_DIR && borg $BORG_ARGS create -x -v --stats --progress --comment '$COMMENT' ::$___REPO_NAME $FILES"
      ansi -n --yellow "   Creating Borg $___REPO_NAME"
      set +e
      eval $cmd
      ansi --yellow "            OK"

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
get_cached_binary_build_script_repo_name(){
    _K="$(get_setup_hash)-$(basename $1)-cached-build_script-binary"
    echo $_K
}
get_cached_build_script_repo_name(){
    _K="$(get_setup_hash)-$1-cached-build_script"
    echo $_K
}
get_cached_build_script(){
    set +e
    SPEC_NAME="$(basename $1 .py).spec"
    MANGLED_VARS_FILE=".$(basename $SPEC_NAME .spec)_mangled_vars.txt"
    ____REPO_NAME=$(get_cached_build_script_repo_name $1)
    cmd="borg list ::$____REPO_NAME $SPEC_NAME --format=\"{path}{NEWLINE}\""
    eval $cmd > .o 2>.e
    ec=$?
    #>&2 ansi --yellow "    [cached_build_script] 1=$1 REPO_NAME=$____REPO_NAME SPEC_NAME=$SPEC_NAME MANGLED_VARS_FILE=$MANGLED_VARS_FILE cmd=$cmd exit_code=$ec"
    if [[ "$ec" == "0" ]]; then
        [[ -f /tmp/$SPEC_NAME ]] && unlink /tmp/$SPEC_NAME
        (cd /tmp && borg $BORG_ARGS extract ::$____REPO_NAME $SPEC_NAME $MANGLED_VARS_FILE) >/dev/null 2>&1
        echo -e "/tmp/$SPEC_NAME\n/tmp/$MANGLED_VARS_FILE"
    else
        echo ""
    fi
    set -e
}
save_binary_to_borg(){
  if [[ "$SAVE_BUILD_TO_BORG" == "1" ]]; then
    __REPO_NAME="$(get_cached_binary_build_script_repo_name $1)"
    modules_file=$(mktemp)
    bs_file=$(mktemp)
    echo "$MODULES"|tr ' ' '\n'|grep -v '^$' > $modules_file
    echo "$BUILD_SCRIPTS"|tr ' ' '\n'|grep -v '^$' > $bs_file
    #jo blah=123 |base64 -w0> .COMMENT-$1
    #cat .COMMENT-$1
    #COMMENT=$(cat .COMMENT-$1)
    COMMENT=123
    file_save_cmd="(borg $BORG_ARGS delete ::$__REPO_NAME >/dev/null 2>&1; cd $(dirname $1) && borg $BORG_ARGS create --comment \"$COMMENT\" -x -v --stats --progress  ::$__REPO_NAME $(basename $1))"
    echo $file_save_cmd > .file_save_cmd
    >&2 ansi --yellow "file_save_cmd saved to .file_save_cmd, MANGLED_VARS_FILE=$MANGLED_VARS_FILE"
    set +e
    bash .file_save_cmd
    file_save_exit_code=$?
    set -e
    >&2 ansi --yellow "     file_save_exit_code=$file_save_exit_code"
  fi
}
save_build_script_to_repo(){
  if [[ "$SAVE_BUILD_TO_BORG" == "1" ]]; then
    ansi --yellow "[save_build_script_to_repo] 1=\"$1\""
    >&2 ansi --yellow "[save_build_script_to_repo] 1=\"$1\""
    _REPO_NAME=$(get_cached_build_script_repo_name $1)
    _DIR="$(dirname $2)"
    MANGLED_VARS_FILE=".$(basename $2 .spec)_mangled_vars.txt"
    file_save_cmd="(borg $BORG_ARGS delete ::$_REPO_NAME >/dev/null 2>&1; cd $ORIG_DIR/$(dirname $2) && cp ../$MANGLED_VARS_FILE . && borg $BORG_ARGS create -x -v --stats --progress  ::$_REPO_NAME $(basename $2) $MANGLED_VARS_FILE)"
    echo $file_save_cmd > .file_save_cmd
    >&2 ansi --yellow "file_save_cmd saved to .file_save_cmd, MANGLED_VARS_FILE=$MANGLED_VARS_FILE"
    set +e
    bash .file_save_cmd
    file_save_exit_code=$?
    set -e
    >&2 ansi --yellow "     file_save_exit_code=$file_save_exit_code"
  fi
}
get_module_md5(){
    if [[ -f "scripts/$1" ]]; then
        _F="scripts/$1"
    elif [[ -f "scripts/${1}.py" ]]; then
        _F="scripts/${1}.py"
    else
        _F="$1"
    fi
#    >&2 ansi --yellow "              [get_module_md5] 1=$1 _F=$_F pwd=$(pwd)"

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
            [[ -f scripts/ansible-${x}.py ]] && unlink scripts/ansible-${x}.py
            [[ -f scripts/ansible-${x} ]] && unlink scripts/ansible-${x}
            cp $(which ansible-${x}) scripts/ansible-${x}.py
          fi

          [[ "$_REMOVE_SHEBANG_LINE_FROM_ANSIBLE_CLI_SCRIPTS" == "1" ]] && head -n 1 scripts/ansible-${x}.py | grep -q '^#!' && sed -i 1d scripts/ansible-${x}.py
        done
        if [[ "$_OVERWRITE_MANAGER_FILE" == "1" ]]; then
            python -m py_compile manager.py
            cp -f manager.py $VIRTUAL_ENV/lib/python3.6/site-packages/ansible/config/manager.py
        fi        

        addAdditionalAnsibleModules plugins callback "$ADDITIONAL_ANSIBLE_CALLLBACK_MODULES"
        addAdditionalAnsibleModules modules library "$ADDITIONAL_ANSIBLE_LIBRARY_MODULES"

    fi

    >&2 ansi --cyan "Installing $(count_required_modules) Python Requirements"
    if [[ "$MODULES" != "" ]]; then
        >&2 pip -q install $MODULES
    fi        
        >&2 ansi --green "  OK"
    
    >&2 ansi --cyan "Installing $(count_required_module_repos) Module Repos"
    if [[ "$MODULE_REPOS" != "" ]]; then
        for x in $(echo $MODULE_REPOS|tr ' ' '\n'|grep -v '^$'|sort -u); do
            >&2 pip install -q $x
        done
    fi
    >&2 ansi --green "  OK"

    if [[ "$BUILD_BORG" == "1" ]]; then
        set -e
        >&2 ansi --yellow "           Fetch BORG Source Code"
        [[ -d _borg ]] || git clone https://github.com/binRick/borg _borg
        (cd _borg && git pull)
        >&2 ansi --yellow "           Install BORG Requirements"
        pip install -q -r _borg/requirements.d/development.txt
        >&2 ansi --yellow "           Install BORG"
        pip install -q -e _borg
        >&2 ansi --green "                  OK"
        [[ ! -f scripts/BORG.py ]] && cp -f _borg/src/borg/__main__.py scripts/BORG.py
        head -n 1 scripts/BORG.py | grep -q '^#!' && sed -i 1d scripts/BORG.py
        [[ ! -f scripts/$_BORG_BUILD_NAME ]] && cp -f scripts/BORG.py scripts/$_BORG_BUILD_NAME
        >&2 ansi --yellow "           Test BORG @$_BORG_BUILD_NAME"
        python scripts/$_BORG_BUILD_NAME --help >/dev/null 2>&1
        >&2 ansi --green "                  OK"
    fi
}


save_modules(){
    set -e
    for m in $BUILD_SCRIPTS; do
#        >&2 ansi --green saving Build Script $m to repo
        save_build_script_to_repo "$m" ".specs/$(basename $m .py).spec"
    done
    

}

run_build(){
    [[ -f .stdout ]] && ansi --yellow "Starting build" > .stdout
    [[ -f .stderr ]] && ansi --yellow "Starting build" > .stderr
    [[ -f .exit_code ]] && echo "" > .exit_code
    set +e
    xpanes -x --stay -l ev -e "tail -n0 -f .*stdout*"
    xpanes -x --stay -l ev -e "tail -n0 -f .*stderr*"
    bash ./build.sh > .stdout 2> .stderr
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
    echo "$DIST_PATH"

#    >&2 ansi --green Validated DIST_PATH $DIST_PATH
}
normalize_dist_path(){
    set -e
    mv $DIST_PATH ${DIST_PATH}.t
    mkdir $DIST_PATH
    mv ${DIST_PATH}.t $DIST_PATH/$_DIR_PATH_PREFIX
    echo $ANSIBLE_CFG_B64|base64 -d > $DIST_PATH/$_DIR_PATH_PREFIX/ansible.cfg
}
test_dist_path(){
    cd $ORIG_DIR
    cmd="BUILD_SCRIPTS=\"$BUILD_SCRIPTS\" \
        ./test.sh $DIST_PATH/$_DIR_PATH_PREFIX"
    eval $cmd
}
relocate_path(){
    if [[ "$_RELOCATE_PATH" == "1" ]]; then
#        >&2 ansi --yellow "   [_RELOCATE_PATH]  _RELOCATE_PATH_PREFIX=$_RELOCATE_PATH_PREFIX"
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
                    cython -${CYTHON_COMPILE_PYTHON_VERSION} --embed \
                        -o $(basename $_tf_bin_path_py_clean .py).c $(basename $_tf_bin_path_py_clean .py).py && \
                    gcc -Os -I ${CYTHON_PYTHON_COMPILE_LIBRARY_PATH} \
                        -o $destination_file_name $(basename $_tf_bin_path_py_clean .py).c \
                        -l${CYTHON_PYTHON_LIBRARY} ${CYTHON_COMPILE_LIBS} && \
                    rm -f $(basename $_tf_bin_path_py_clean .py).py $(basename $_tf_bin_path_py_clean .py).c && \
                    $rename_cmd \
\n"
#            >&2 ansi --cyan "            j_cmd=$j_cmd"
            echo -e $j_cmd > $_bin_jinja_cmd
            bash $_bin_jinja_cmd
            exit_code=$?
            if [[ "$exit_code" != "0" ]]; then
                >&2 ansi --red "$(cat $_bin_jinja_stderr)"
                exit $exit_code
            fi
            >&2 ansi --green "  ****   Rendered $B to $_tf using bash script $_bin_jinja_cmd and moved it to $destination_file_name ****   "
        done
    fi
}

test_borg(){
    if [[ "$BUILD_BORG" == "1" ]]; then
        MYBORG_PATH="$DIST_PATH/ansible-playbook/bin/$_BORG_BUILD_NAME"
        if [[ ! -e $MYBORG_PATH ]]; then
            >&2 ansi --red "Invalid MYBORG_PATH :: borg is not executable: \"$MYBORG_PATH\""
            exit 666
        fi
        test_passphrase_cmd="(cd $ORIG_DIR && source /etc/.ansi && source ../constants.sh && source ../utils.sh && source run-constants.sh && source run-vars.sh && source run-utils.sh && doTestBorg \"$MYBORG_PATH\")"
        test_encrypted_passphrase_cmd="(cd $ORIG_DIR && source /etc/.ansi && source ../constants.sh && source ../utils.sh && source run-constants.sh && source run-vars.sh && source run-utils.sh && doPassphraseTests \"$MYBORG_PATH\")"
        >&2 ansi --yellow "test_passphrase_cmd=\"$test_passphrase_cmd\""
        >&2 ansi --yellow "test_encrypted_passphrase_cmd=\"$test_encrypted_passphrase_cmd\""
        eval $test_passphrase_cmd
        test_passphrase_cmd_exit_code=$?
        eval $test_encrypted_passphrase_cmd
        test_encrypted_passphrase_cmd_exit_code=$?
    fi
}
count_required_module_repos(){
    echo -e "$MODULE_REPOS"|tr ' ' '\n'|grep -v '^$'|sort -u|wc -l
}
count_required_modules(){
    echo -e "$MODULES"|tr ' ' '\n'|grep -v '^$'|sort -u|wc -l
}
count_binaries(){
    echo 666
}
count_modules(){
    findAllVenvModules 2>/dev/null | wc -l
}

summary(){
    >&2 echo -e "\n\n"
    >&2 ansi --green "Binaries: $(count_binaries)"
    >&2 ansi --green "Required Modules: $(count_required_modules)"
    >&2 ansi --green "Python Modules: $(count_modules)"
    >&2 ansi --green "Disk Usage: $(du --max-depth=1 -h $DIST_PATH)"
    >&2 ansi --green "File Count: $(find $DIST_PATH -type f|wc -l)"
    >&2 ansi --green "Directory Count: $(find $DIST_PATH -type d|wc -l)"
    >&2 echo -e "\n\n"
}

build_script_repo_names(){
    for _REPO in $(borg list $BORG_REPO $BORG_ARGS --format="{name}{NEWLINE}"|grep 'cached-build_script-binary$'|sort -u); do
        _REPO_BINARY="$(echo "$_REPO"| cut -d'-' -f2|sort -u)"
        _REPO_COMMENT="$(borg info ::$_REPO|grep '^Command: ')"
        echo _REPO=$_REPO, _REPO_BINARY=$_REPO_BINARY, _REPO_COMMENT=$_REPO_COMMENT

    done
}
repo_names(){
    QTY=$1
    [[ "$QTY" == "" ]] && export QTY=10
    borg list $BORG_REPO $BORG_ARGS --format="{name}{NEWLINE}" | grep '^.COMBINED-' | tail -n $QTY
}
repo_name_build_scripts(){
    borg info ::$1|grep '^Comment: '|cut -d' ' -f2|base64 -d|jq '.build_scripts' -Mrc
}
repo_name_modules(){
    borg info ::$1|grep '^Comment: '|cut -d' ' -f2|base64 -d|jq '.modules' -Mrc
}

repo_info_json(){
    modules_file=$(mktemp)
    bs_file=$(mktemp)
    for r in $(repo_names 15); do
      set +e
      repo_name_modules $r|tr ' ' '\n' | tr '\n' ','|grep -v '^$' |sed 's/,$//g' > $modules_file
      repo_name_build_scripts $r|tr ' ' '\n' | tr '\n' ','|grep -v '^$' | sed 's/,$//g' > $bs_file
      set -e
      jo_cmd="jo repo=$r modules=@$modules_file build_scripts=@$bs_file"
      eval $jo_cmd
    done
}

