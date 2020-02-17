#!/bin/bash 
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
set -e

REPO_NAME="$(basename $(cd ../ && pwd))"
REMOTE_REPO_DIR=/root
REMOTE_REPO_PATH="$REMOTE_REPO_DIR/$REPO_NAME"
LOCAL_REPO_PATH="$(cd ../ && pwd)"

echo LOCAL_REPO_PATH=$LOCAL_REPO_PATH
echo REMOTE_REPO_PATH=$REMOTE_REPO_PATH
echo REPO_NAME=$REPO_NAME

REMOTE_SERVER=$1
if [[ "$REMOTE_SERVER" == "" ]]; then echo first argument must be remote server; exit 1; fi

cmd="ssh -q root@$REMOTE_SERVER rm -rf $REMOTE_REPO_PATH; rsync -ar -e 'ssh -q' $LOCAL_REPO_PATH root@$REMOTE_SERVER:$REMOTE_REPO_DIR && ssh -q root@$REMOTE_SERVER \"REPO_PATH=$REMOTE_REPO_PATH $REMOTE_REPO_PATH/compiler/COMPILER.sh\""
echo cmd=$cmd
eval $cmd
exit_code=$?

exit 
if [[ -d /home/COMPILER ]]; then
    sudo rm -rf /home/COMPILER
fi

if [[ ! -d /home/COMPILER ]]; then
    sudo mkdir -p /home/COMPILER
    sudo chown -R COMPILER:COMPILER /home/COMPILER 
    sudo chmod -R 700 /home/COMPILER
fi

sudo rm -rf \
    ~COMPILER/ansible-bundle-playbook-dev ~COMPILER/.venv* /tmp/__pycache__ ~COMPILER/build \
    /tmp/PATCHED_MAIN_BINARIES.txt


sudo rsync $LOCAL_REPO_PATH ~COMPILER/. -ar

sudo -Hi -u COMPILER \
    BUILD_ONLY=1 \
    MANGLE_MAIN_BINARY=0 \
    ANSIBLE_VERSION=2.8.8 \
    DEBUG_MAIN_BINARY_BUILD=0 \
    INCLUDE_ANSIBLE_TOOLS=0 \
        ./ansible-bundle-playbook-dev/compiler/compileAnsible.sh | tee ~/.ansible-bundler-log-$(date +%s).txt
