#!/usr/bin/env bash
umask 002
BORG_ARCHIVE_QUOTA="5G"  # Max Disk Space borg repo can use
BORG_ARCHIVE=~/ansible-playbook.borg
BORG_SSH_KEY="BORG_KEY"
BORG_SSH_PORT=22
BORG_SSH_HOST=web1
BORG_SSH_USER=BORG
TYPES="onedir onefile"
TYPES="onedir"
setupSshAgent(){
    if [ "$PRIVATE_KEY_ENCODED" == "" ]; then
        echo
        echo PRIVATE_KEY_ENCODED environment variable needs to contain private key
        echo "You can create it using \"PRIVATE_KEY_ENCODED=\$(cat /path/to/key | base64 -w0)\""
        echo
        echo
        exit 1
    fi
    set -e
    export SSH_AUTH_SOCK="$(mktemp -u -p ~ --suffix _sshAgent_socket)"
    coproc agentProcess { exec ssh-agent -dsa $SSH_AUTH_SOCK; }
    export K="$(cat BORG_KEY |base64 -w0)"
    echo $PRIVATE_KEY_ENCODED | base64 -d | ssh-add -
}

CREATED=0
BORG_CREATE_COMPRESSION="none"
BORG_CREATE_COMPRESSION="lzma" # Better Compression
BORG_CREATE_COMPRESSION="lz4"  # Faster
BORG_CREATE_COMPRESSION="auto,lzma,6"
ANSIBLE_TEST_ENV="ANSIBLE_NOCOWS=True ANSIBLE_PYTHON_INTERPRETER=auto_silent ANSIBLE_FORCE_COLOR=1 ANSIBLE_VERBOSITY=0 ANSIBLE_DEBUG=False ANSIBLE_LOCALHOST_WARNING=False ANSIBLE_SYSTEM_WARNINGS=True ANSIBLE_RETRY_FILES_ENABLED=False ANSIBLE_DISPLAY_ARGS_TO_STDOUT=True ANSIBLE_DEPRECATION_WARNINGS=False ANSIBLE_NO_TARGET_SYSLOG=True"
PLAYBOOK_FILE=~/.tp.yaml
start_ts="$(date +%s)"
if [ "$DELETE_ARCHIVE" == "1" ]; then
    echo "Deleting ${BORG_ARCHIVE}..."
    rm -rf $BORG_ARCHIVE
fi
if [ "$QTY" == "" ]; then
    QUANTITY_OF_LATEST_ANSIBLE_RELEASES=10
else
    QUANTITY_OF_LATEST_ANSIBLE_RELEASES="$QTY"
fi
export BORG_PASSPHRASE="123123"

BORG_BINARY="borg-linux64"
BORG_OPTIONS="--lock-wait 300"

JQ="$(which jq)"
set +e; $JQ --version >/dev/null 2>&1 || {
    mkdir -p ~/.local/bin
    wget -4 https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 -O ~/.local/bin/jq
    chmod +x ~/.local/bin/jq
    export JQ=~/.local/bin/jq
}
set -e

writeTestPlaybook(){
    cat > $PLAYBOOK_FILE <<EOF
---
- name: test playbook
  hosts: all
  gather_facts: no
  connection: local
  become: no
  tasks:
   - name: id test
     command: id
EOF
echo $PLAYBOOK_FILE
}

installJo(){
  set +e
  command jo -v >/dev/null 2>&1 || \
     ~/.local/bin/jo -v >/dev/null 2>&1 || {
   (
    cd
    set +e
    rm -rf jo-1.2.tar.gz
    set -e
    wget -4 https://github.com/jpmens/jo/releases/download/1.2/jo-1.2.tar.gz
    tar zxvf jo-1.2.tar.gz
    cd jo-1.2
    (./configure --prefix=/usr/local && make) >/dev/null
    ./jo -v >/dev/null
    set +e
    mkdir -p ~/.local/bin
    set -e
    cp jo ~/.local/bin/.
    alias jo=~/.local/bin/jo
   )
   set -e
  }
}

getSitePackagesPath(){
        pip show ansible|grep ^Location:|cut -d' ' -f2| grep "^\/"|head -n 1
}
limitAnsibleVersions(){
    egrep "2.8.7"
}
findAnsibleModules(){
   (
        cd $1/
        find ansible \
                | grep '\.py$'|grep '/'  | sed 's/\.py//g' | sed 's/\/__init__//g'

        find ansible \
                | grep '\.py$'| grep __init__.py$ |grep '/'| grep '/' | sed 's/\/__init__.py$//g'
   ) | sort | uniq
}

mangleModules(){
    sed 's/\//./g'| xargs -I % echo -e "         --hidden-import=\"%\" "
}


buildPyInstallerCommand(){
    ANSIBLE_MODULES="$(findAnsibleModules $(getSitePackagesPath) | mangleModules)"

    echo pyinstaller \
        -n ansible-playbook \
        --$type -y --clean \
        --distpath $DIST_PATH \
           \
            --add-data .venv/lib/python3.6/site-packages/ansible/config/base.yml:ansible/config \
            --add-data .venv/lib/python3.6/site-packages/ansible/config/module_defaults.yml:ansible/config \
            --add-data .venv/lib/python3.6/site-packages/ansible/utils/shlex.py:ansible/utils \
            --add-data .venv/lib/python3.6/site-packages/ansible/plugins/cache:ansible/plugins/cache \
            --add-data .venv/lib/python3.6/site-packages/ansible/module_utils:ansible/module_utils \
            --add-data .venv/lib/python3.6/site-packages/ansible/modules:ansible/modules \
            --add-data .venv/lib/python3.6/site-packages/ansible/plugins/inventory:ansible/plugins/inventory \
            --add-data .venv/lib/python3.6/site-packages/ansible/plugins:ansible/plugins \
            --add-data .venv/lib/python3.6/site-packages/ansible/executor/discovery/python_target.py:ansible/executor/discovery \
           \
            --hidden-import=terminaltables \
            --hidden-import=configparser \
            --hidden-import=distutils.spawn \
            --hidden-import=xml.etree \
            --hidden-import=pty \
            --hidden-import=distutils.version \
            --hidden-import=xml.etree.ElementTree \
            --hidden-import=csv \
            --hidden-import=smtplib \
            --hidden-import=logging.handlers \
           \
                ${ANSIBLE_MODULES} \
            \
             .venv/bin/ansible-playbook

}

ansibleReleaseInfo(){
    curl -s4 https://pypi.org/pypi/ansible/json |jq ".releases[\"$1\"]"
}

validateAnsible(){
        ls -alhS $DIST_PATH/ansible-playbook
        $DIST_PATH/ansible-playbook --version
}

ignoreAnsibleVersions(){
    grep -v "^2.7" \
        |grep -v "^2.6"
}

getAnsibleVersions(){
    curl -s4 https://pypi.org/pypi/ansible/json \
        | $JQ '.releases' | $JQ keys| grep '"[0-9]\.[0-9]\.[0-9].*"' \
        | sed 's/"//g'|sed 's/,//g' \
        | sed 's/[[:space:]]//g'|sort -r \
        | ignoreAnsibleVersions \
        | limitAnsibleVersions \
        | head -n $QUANTITY_OF_LATEST_ANSIBLE_RELEASES
}
export ANSIBLE_VERSIONS="$(getAnsibleVersions|tr '\n' ' ')"

set +e; $BORG_BINARY --version >/dev/null 2>&1 || {
    mkdir -p ~/.local/bin
    wget https://github.com/borgbackup/borg/releases/download/1.1.10/borg-linux64 -O ~/.local/bin/borg-linux64
    chmod +x ~/.local/bin/borg-linux64
    export BORG_BINARY=~/.local/bin/borg-linux64
    alias borg="$BORG_BINARY"
    alias borg-linux64="$BORG_BINARY"
}

doMain(){
    set -e
    installJo

    if [ ! -d $BORG_ARCHIVE ]; then
        $BORG_BINARY init --encryption repokey --storage-quota $BORG_ARCHIVE_QUOTA --make-parent-dirs $BORG_ARCHIVE 2>/dev/null
    fi
    $BORG_BINARY $BORG_OPTIONS info $BORG_ARCHIVE
    $BORG_BINARY $BORG_OPTIONS list $BORG_ARCHIVE

    for ANSIBLE_VERSION in $ANSIBLE_VERSIONS; do
      for type in $TYPES; do
        pb_start_ts="$(date +%s)"
        cd
        DIST_PATH="ansible-playbook-$ANSIBLE_VERSION-$type"
        set +e
        $BORG_BINARY $BORG_OPTIONS list $BORG_ARCHIVE | grep "^${ANSIBLE_VERSION}-${type}" >/dev/null && {
            echo "$ANSIBLE_VERSION ($type) exists in $BORG_ARCHIVE. Skipping.."
            continue
        }
        set -e
        echo "Processing $ANSIBLE_VERSION $type"
        cd
        if [ "$type" == "onefile" ]; then
            PLAYBOOK_BINARY_PATH=$DIST_PATH/ansible-playbook
        elif [ "$type" == "onedir" ]; then
            PLAYBOOK_BINARY_PATH=$DIST_PATH/ansible-playbook/ansible-playbook
        else
            echo Failure
            exit 1
        fi

        if [ -d .venv ]; then
            rm -rf .venv
        fi
        python3 -m venv .venv
        source .venv/bin/activate
        pip install pip --upgrade -q
        pip install pyinstaller --upgrade -q
        
        if [ -d $DIST_PATH ]; then rm -rf $DIST_PATH; fi
        pip uninstall ansible --yes -q 2>/dev/null
        pip install "ansible==${ANSIBLE_VERSION}" --upgrade --force -q

        CMD="$(buildPyInstallerCommand)"
        if [ "$DEBUG_CMD" == "1" ]; then
            echo $CMD
            exit 
        fi
        ANSIBLE_MODULES_QTY="$(findAnsibleModules $(getSitePackagesPath) | mangleModules|tr ' ' '\n'|grep '^--hidden-import='|wc -l)"
        echo "Building binary with $ANSIBLE_MODULES_QTY modules"
        (eval "$CMD")
        echo "Finished Building binary"
        pb_duration=$(($(date +%s)-$pb_start_ts))

        set -e
        file $PLAYBOOK_BINARY_PATH | grep '^ansible-playbook' | grep ': ELF 64-bit LSB executable, x86-64' && echo Valid File
        $PLAYBOOK_BINARY_PATH --version | grep '^ansible-playbook $ANSIBLE_VERSION' && echo Valid Version
        
        echo "Configuring Ansible Environment.."
        source <(echo $ANSIBLE_TEST_ENV |tr ' ' '\n'|xargs -I % echo export %)
        echo "Executing Test Playbook"
        $PLAYBOOK_BINARY_PATH -i localhost, -c local $(writeTestPlaybook)
        cd $DIST_PATH

        ansibleReleaseInfo $ANSIBLE_VERSION | $JQ '.[]' > .ANSIBLE-RELEASE.JSON
        jo -p ended_ts=$(date +%s) version=$ANSIBLE_VERSION type=$type buildTime=$pb_duration \
              compression=$BORG_CREATE_COMPRESSION hostname="$(hostname -f)" os="$(uname)" \
              arch="$(uname -m)" kernel="$(uname -r)" distro="$(cat /etc/redhat-release)" \
              ansible_modules_qty="$ANSIBLE_MODULES_QTY" \
          > .METADATA.JSON

        COMMENT="ansible-playbook version=${ANSIBLE_VERSION} type=$type buildTime=$pb_duration \
                 compression=$BORG_CREATE_COMPRESSION hostname=$(hostname -f) os=$(uname) \
                 user="$USER" buildStartTime="$pb_start_ts" \
                 arch=$(uname -m) kernel=$(uname -r) distro=$(cat /etc/redhat-release)"

        $BORG_BINARY $BORG_OPTIONS create \
            --compression $BORG_CREATE_COMPRESSION \
            --progress --comment "$COMMENT" -v --stats $BORG_ARCHIVE::${ANSIBLE_VERSION}-${type} \
            ansible-playbook .METADATA.JSON .ANSIBLE-RELEASE.JSON

        CREATED=$((CREATED+1))
        cd
        rm -rf $DIST_PATH

      done
    done
    duration=$(($(date +%s)-$start_ts))

    $BORG_BINARY $BORG_OPTIONS info $BORG_ARCHIVE
    $BORG_BINARY $BORG_OPTIONS list $BORG_ARCHIVE

    echo "OK- Created $CREATED ansible-playbook binaries in $duration seconds."
}

doMain
