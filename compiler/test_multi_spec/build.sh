#!/bin/bash
set -e
python3 -m venv .venv
rm -rf build dist __pycache__
source .venv/bin/activate
pip install \
    setproctitle \
    pyaml \
    psutil \
    paramiko
#    ansible==2.8.8 \

#    --hidden-import="ansible" \

pyi-makespec \
    --hidden-import="paramiko" \
    --hidden-import="pyaml" \
    --hidden-import="psutil" \
    -p ./venv/lib64/python3.6/site-packages \
        test.spec

pyinstaller \
    --clean -y \
        test.spec 


./dist/test/test
