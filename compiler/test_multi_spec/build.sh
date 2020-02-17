#!/bin/bash
set -e
python3 -m venv .venv
rm -rf build dist __pycache__
source .venv/bin/activate
pip install setproctitle

pyi-makespec test.spec
pyinstaller -y --clean \
    --hidden-import=setproctitle \
    --hidden-import=json \
        test.spec 


./dist/test/test
