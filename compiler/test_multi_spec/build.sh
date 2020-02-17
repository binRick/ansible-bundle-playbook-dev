#!/bin/bash
set -e
python3 -m venv .venv
rm -rf build dist __pycache__
source .venv/bin/activate
pip install \
    setproctitle \
    pyaml \
    psutil \
    python-prctl \
    paramiko

pyi-makespec \
    --hidden-import="paramiko" \
    --hidden-import="pyaml" \
    -p ./venv/lib64/python3.6/site-packages \
        test.spec

pyinstaller \
    --clean -y \
        test.spec 


./dist/test/test
