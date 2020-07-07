#!/bin/bash
set -e
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source /etc/.ansi

export GET_MODULES_QTY_CMD="{ $(pwd)/getModules.sh 2>/dev/null |cut -d'.' -f1|sort|uniq -c|sort -n|tr -s ' '|sed 's/^[[:space:]]//g'; }"
export GET_MODULES_QTY_CMD="find  .venv-1/lib/python3.6/site-packages -type d |cut -d'/' -f5|sort -u|grep -v egg|grep dist-info -v|grep -v '^\.'|grep -v '^$'|sort -u"

(eval $GET_MODULES_QTY_CMD 2>/dev/null || echo 0; )|cut -d' ' -f2|while read -r line; do
    _d=".venv-1/lib/python3.6/site-packages/$line"
    [[ -d "$_d" ]] && \
        echo -ne "$line " && 
        du --max-depth=0 $_d -b|tr -s ' ' |sed 's/[[:space:]]/ /g'|cut -d' ' -f1
done | while read -r module_name module_bytes; do
    echo -e "$module_bytes $module_name"
done |sort -n

