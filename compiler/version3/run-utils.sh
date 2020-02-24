load_vars(){
    >&2 ansi --cyan "  Loading $(wc -l vars.sh) Vars.."
    source vars.sh
}

setup_venv(){
    [[ ! -d $SAVE_MODULE_PATH ]] && mkdir -p $SAVE_MODULE_PATH
    #if [[ -d .venv-1 ]]; then rm -rf .venv-1; fi
    [[ -d .venv-1 ]] || python3 -m venv .venv-1
    source .venv-1/bin/activate
    pip -q install pip --upgrade
    pip -q install ansible==$ANSIBLE_VERSION

    for x in playbook config vault; do
      [[ -f ansible-${x}.py ]] && unlink ansible-${x}.py
      [[ -f ansible-${x} ]] && unlink ansible-${x}
      cp $(which ansible-${x}) ansible-${x}.py
      head -n 1 ansible-${x}.py | grep -q '^#!' && sed -i 1d ansible-${x}.py
    done

    [[ -d _borg ]] || git clone https://github.com/binRick/borg _borg
    (cd _borg && git pull)
    pip install -q -r _borg/requirements.d/development.txt
    pip install -q -e _borg
    cp -f _borg/src/borg/__main__.py BORG.py
    head -n 1 BORG.py | grep -q '^#!' && sed -i 1d BORG.py
    python BORG.py --help >/dev/null 2>&1
    >&2 ansi --green Pre compile BORG.py validated OK
}

get_module_saved_path(){
    _MODULE=$1
    _MODULE_MD5=$(echo $_MODULE|md5sum | cut -d' ' -f1)
    echo "$SAVE_MODULE_PATH/$_MODULE_MD5"
}

save_modules(){
    for m in $BUILD_SCRIPTS; do
        save_path=$(get_module_saved_path $m)
        cp_cmd="cp $DIST_PATH/ansible-playbook/$m $save_path"
        >&2 ansi --yellow "      Saving Build Script $m to $save_path with cmd:$(echo -e "\n\n           \"$cp_cmd\"\n\n")"
        >&2 pwd
    done
}

run_build(){
    [[ -f .stdout ]] && unlink .stdout
    [[ -f .stderr ]] && unlink .stderr
    [[ -f .exit_code ]] && unlink .exit_code
    set -e
    bash -x ./build.sh > .stdout 2> .stderr
    exit_code=$?
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
