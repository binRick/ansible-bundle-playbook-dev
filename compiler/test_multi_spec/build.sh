#!/bin/bash
set -e
python3 -m venv .venv
rm -rf build dist __pycache__
source .venv/bin/activate
pip install setproctitle

pyi-makespec \
    --hidden-import="setproctitle" \
    -p ./venv/lib64/python3.6/site-packages \
        test.spec

pyinstaller \
    --clean -y \
        test.spec 


./dist/test/test
