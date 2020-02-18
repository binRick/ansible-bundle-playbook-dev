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
    pyinstaller \
    setproctitle \
    pyaml \
    psutil \
    paramiko

for x in test test1; do 

    echo -e "Working on file \"$x\""

    pyi-makespec \
        --hidden-import="paramiko" \
        --hidden-import="pyaml" \
        --hidden-import="psutil" \
        -p ./venv/lib64/python3.6/site-packages \
           ${x}.py > ${x}-makespec.stdout 2> ${x}-makespec.stderr
    exit_code=$?


    pyinstaller \
        --clean -y \
            ${x}.spec > ${x}-compile.stdout 2> ${x}-compile.stderr
    exit_code=$?

    echo -e "   OK"

done 


./dist/test/test
