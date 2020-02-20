#!/bin/bash
set -e
(set +e;sudo useradd C2;) >/dev/null 2>&1
set -e
[[ ! -d ~C2/.BUILD ]] && sudo mkdir -p ~C2/.BUILD

sudo rsync $(cat BUILD_FILES.txt) ~C2/.BUILD/.

sudo chown -R C2:C2 /home/C2/.BUILD

