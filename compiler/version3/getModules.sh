#!/bin/bash
set -e
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
(cd ~/vpntech-ioncube-encoder/ansible-bundle-playbook-dev/compiler/version3 && source .venv-1/bin/activate && source /etc/.ansi && source ../constants.sh && source ../utils.sh && source run-constants.sh && source run-vars.sh && source run-utils.sh && findAllVenvModules 2>/dev/null)
#grep hidden-import .combined-spec-cmd.sh|cut -d'"' -f2
#./getModules.sh|cut -d'.' -f1|sort|uniq -c|sort -k1
