#!/bin/bash
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source setup.sh
set -e
repo_names | \
    fzf \
        --tac \
        --border \
        --header="Select Borg Repo" \
        --preview="\
             echo -e ::     {}    ::;\
        \
        echo;echo;echo '---------------------';\
        echo -e \"    Build Scripts:\";\
        echo '---------------------';echo;\
        borg info ::{} 2>/dev/null |grep '^Comment: '|cut -d' ' -f2|base64 -d|jq '.build_scripts' -r|grep '\"' |cut -d'\"' -f2|sort -u|column -c 80;\
        echo;echo;echo '-----------------';\
        echo -e \"    Modules:\";\
        echo '-----------------';\
        echo;\
        borg info ::{} 2>/dev/null|grep '^Comment: '|cut -d' ' -f2|base64 -d|jq '.modules' -r|grep '\"' |cut -d'\"' -f2|sort -u|column -c 80" \
        \
        \
        
