#!/bin/bash
cd "$( dirname "${BASH_SOURCE[0]}" )"
INSTALL_BASE=~/.ansible-onedirs
if [[ "$1" == "" ]]; then
    echo First Argument must be ansible version
    exit 1
fi
if [[ ! -d "$INSTALL_BASE/$1" ]]; then
    echo https://github.com/binRick/ansible-bundle-playbook-dev/raw/master/compiled/2.8.7-onedir.tar.bz2
fi
