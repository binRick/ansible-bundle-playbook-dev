#!/bin/bash
set +e
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )


MODULES="click pyyaml blessed json2yaml click_threading ansible_runner jinja2 paramiko paramiko_expect jsondiff netaddr rich"

set +x





rm -rf dist build _borg .venv-1; python3 -m venv .venv-1 && source .venv-1/bin/activate && pip install pip --upgrade && pip install pyinstaller $MODULES

exit
deactivate
source .venv-1/bin/activate
pip freeze
