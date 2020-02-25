

ensure_borg(){
 [[ -d $BORG_REPO ]] || command borg $BORG_ARGS init -e repokey
 borg check $BORG_ARGS
 borg prune $BORG_ARGS -v -p --keep-within ${BORG_KEEP_WITHIN_DAYS}d 2>/dev/null
}
save_build_to_borg(){
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
  cmd="cd $(dirname $BUILD_DIR) && borg $BORG_ARGS create -x -v --stats --progress --comment '$COMMENT' ::$REPO_NAME $REPO_NAME"
  ansi --yellow $cmd
  eval $cmd

  set -e
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
    _K="$(get_module_md5 $1)-$1-cached-build_script"
    echo $_K
}
get_cached_build_script(){
    set +e
    REPO_NAME=$(get_cached_build_script_repo_name $1)
    cmd="borg list ::$REPO_NAME"
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
    REPO_NAME=$(get_cached_build_script_repo_name $1)
    REPO_ENV_NAME=$(get_cached_build_script_repo_env_name $1)
    file_save_cmd="(cd $(dirname $2) && borg $BORG_ARGS create -x -v --stats --progress  ::$REPO_NAME $(basename $2))"
    _DIR="$(dirname $2)"
    _FILES="$(cd $_DIR && find .|tr '\n' ' ')"
    env_save_cmd="cd $_DIR && borg $BORG_ARGS create -x -v --stats --progress  ::$REPO_ENV_NAME $_FILES"
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
}
get_module_md5(){
    (
      md5sum $1 
      echo $1 |md5sum
      echo $MODULES|md5sum
    ) \
      | md5sum | cut -d' ' -f1
}
get_mangled_saved_path(){
    _MODULE=$1
    _MODULE_MD5=$(get_module_md5 $_MODULE)
    echo "$SAVE_MODULE_PATH/${_MODULE}_${_MODULE_MD5}.mangled"
}
get_spec_saved_path(){
    _MODULE=$1
    _MODULE_MD5=$(get_module_md5 $_MODULE)
    echo "$SAVE_MODULE_PATH/${_MODULE}_${_MODULE_MD5}.spec"
}
get_module_saved_path(){
    _MODULE=$1
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
        for x in playbook config vault; do
          [[ -f ansible-${x}.py ]] && unlink ansible-${x}.py
          [[ -f ansible-${x} ]] && unlink ansible-${x}
          cp $(which ansible-${x}) ansible-${x}.py
          head -n 1 ansible-${x}.py | grep -q '^#!' && sed -i 1d ansible-${x}.py
        done
    fi
    
    if [[ "$BUILD_BORG" == "1" ]]; then
        [[ -d _borg ]] || git clone https://github.com/binRick/borg _borg
        (cd _borg && git pull)
        pip install -q -r _borg/requirements.d/development.txt
        pip install -q -e _borg
        cp -f _borg/src/borg/__main__.py BORG.py
        head -n 1 BORG.py | grep -q '^#!' && sed -i 1d BORG.py
        python BORG.py --help >/dev/null 2>&1
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
