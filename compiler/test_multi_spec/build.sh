#!/bin/bash
set -e
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

if [[ -d .venv ]]; then rm -rf .venv; fi
for d in build dist __pycache__; do 
    if [[ -d $d ]]; then rm -rf $d; fi
done

python3 -m venv .venv
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
