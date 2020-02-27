#!/bin/bash
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source setup.sh
set -e
repo_names | \
    fzf --border \
        --preview="\
        \
        \
        echo Build Scripts for {}:;echo;\
        borg info ::{}|grep '^Comment: '|cut -d' ' -f2|base64 -d|jq '.build_scripts' -Mrc;echo;echo '---------';echo;\
        echo Modules:;echo;\
        borg info ::{}|grep '^Comment: '|cut -d' ' -f2|base64 -d|jq '.modules' -Mrc" \
        \
        \
        --header="Select Application Type to generate Token for" \
        \
        \
        --tac
