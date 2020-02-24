load_vars(){
    >&2 ansi --cyan "  Loading $(wc -l vars.sh) Vars.."
    source vars.sh
}

setup_venv(){
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

