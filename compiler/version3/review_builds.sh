#!/bin/bash
set -e
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source setup.sh
repo_names | fzf --border --preview="echo Build Scripts for {}:;echo && bash -c \"borg info ::{}|grep '^Comment: '|cut -d' ' -f2|base64 -d|jq '.build_scripts' -Mrc\" && echo;echo Modules:;echo; bash -c \"borg info ::{}|grep '^Comment: '|cut -d' ' -f2|base64 -d|jq '.modules' -Mrc\"" --header="Select Application Type to generate Token for"
