#!/bin/bash
set -e
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
SRC_DIR=~/ansible-playbook-2.8.8-onedir/ansible-playbook


if [[ "$STATIC_ANSIBLE_PATH" == "" ]]; then export STATIC_ANSIBLE_PATH=/opt/ansible; fi

if [[ ! -d "$SRC_DIR" ]]; then
    >&2 echo $SRC_DIR does not exist
    exit 1
fi

if [[ -d "$STATIC_ANSIBLE_PATH" ]]; then
    sudo rm -rf "$STATIC_ANSIBLE_PATH"
fi

sudo mv $SRC_DIR $STATIC_ANSIBLE_PATH

sudo chmod 0755 $STATIC_ANSIBLE_PATH $STATIC_ANSIBLE_PATH/*.sh $STATIC_ANSIBLE_PATH/ansible-playbook


