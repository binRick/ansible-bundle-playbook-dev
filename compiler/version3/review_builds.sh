#!/bin/bash
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source setup.sh
set -e
repo_names | \
    fzf \
        --tac
        --border \
        --header="Select Application Type to generate Token for" \
        --preview="\
             echo -e ::     {}    ::;\
        \
        echo;echo;echo '-----------------';\
        echo Build Scripts:;\
        echo '-----------------';echo;\
        borg info ::{}|grep '^Comment: '|cut -d' ' -f2|base64 -d|jq '.build_scripts' -Mrc;\
        echo;echo;echo '-----------------';\
        echo Modules:;\
        echo '-----------------';\
        echo;\
        borg info ::{}|grep '^Comment: '|cut -d' ' -f2|base64 -d|jq '.modules' -Mrc" \
        \
        \
        
