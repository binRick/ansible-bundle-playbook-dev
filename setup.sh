#!/bin/bash
set -e
set -m
cd "$( dirname "${BASH_SOURCE[0]}" )"
INSTALL_BASE=~/.ansible-onedirs
if [[ "$INSTALL_VERSION" != "" ]]; then
    1="$INSTALL_VERSION"
fi
if [[ ! -d $INSTALL_BASE ]]; then
    command mkdir -p $INSTALL_BASE
fi
if [[ "$1" == "" ]]; then
    echo First Argument must be ansible version
    exit 1
fi
    _URL="https://raw.githubusercontent.com/binRick/ansible-bundle-playbook-dev/master/compiled/$1-onedir.tar.bz2"
    _DIR="$INSTALL_BASE/$1"
    _DIR_BIN="$INSTALL_BASE/$1/ansible-playbook"
    _CMD="rm -rf $INSTALL_BASE/.tmp >/dev/null 2>&1; command mkdir -p $INSTALL_BASE/.tmp && command curl -s $_URL | command tar jxf - -C $INSTALL_BASE/.tmp && mv $INSTALL_BASE/.tmp/ansible-playbook $_DIR"
if [[ ! -d "$INSTALL_BASE/$1" ]]; then
    if [[ "$_DEBUG" == "1" ]]; then
        echo _URL=$_URL
        echo _DIR=$_DIR
        echo _DIR_BIN=$_DIR_BIN
        echo _CMD=$_CMD
    fi
    if [[ ! -f "$_DIR_BIN" ]]; then
        if [[ "$_DEBUG" == "1" ]]; then
            echo Downloading $1
        fi
        set +e
        eval bash -c "$_CMD"
        exit_code=$?
        set -e
        if [[ "$exit_code" != "0" ]]; then
            echo -e "\n\n[FAIL] exit_code=$exit_code"
            echo -e "[FAIL] _CMD=$_CMD\n\n"
            exit $exit_code
        fi
    fi
fi

set +e
__CMD="$_DIR_BIN --version \
    | grep \"^ansible-playbook ${1}$\" \
"
version_code=$?
set -e
if [[ "$version_code" != "0" ]]; then
            echo -e "\n\n[FAIL] version_code=$version_code"
            echo -e "[FAIL] __CMD=$__CMD\n\n"
            exit $version_code
fi

echo $_DIR_BIN
exit 0
