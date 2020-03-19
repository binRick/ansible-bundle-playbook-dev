#!/bin/bash
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source setup.sh
set -e

QTY="$1"
if [[ "$QTY" == "" ]]; then
  QTY=5
fi


get_combined_borg_repos_json $QTY
