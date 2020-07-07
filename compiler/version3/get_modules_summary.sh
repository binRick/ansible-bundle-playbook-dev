#!/bin/bash
source /etc/.ansi
ansi --yellow --underline --bg-black "Top Modules by size: " && ./getModulesBytes.sh|tail -n 10


ansi --yellow --underline --bg-black "Top Ansible Dirs by qty: " && ./getModules.sh 2>/dev/null|grep ansible|cut -d'.' -f2|sort |uniq -c|sort -n|tail -n5
