#!/bin/bash
set -e
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
rm -rf BUNDLED
mkdir BUNDLED
bundle-playbook -f pb.yaml -o BUNDLED/PB -a 2.8.6 -v vars.json -p requests -p pyvmomi -d testTemplate.j2
