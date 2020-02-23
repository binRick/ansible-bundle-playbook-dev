#!/bin/bash
#set -e
[[ "$BUILD_USER" == "" ]] && export BUILD_USER="C2"

(sudo useradd $BUILD_USER;) >/dev/null 2>&1
set -e
[[ -d ~$BUILD_USER/.BUILD ]] && sudo rm -rf ~$BUILD_USER/.BUILD
[[ ! -d ~$BUILD_USER/.BUILD ]] && sudo mkdir -p ~$BUILD_USER/.BUILD

sudo rsync $(cat BUILD_FILES.txt) ~$BUILD_USER/.BUILD/.

sudo chown -R $BUILD_USER:$BUILD_USER /home/$BUILD_USER/.BUILD


sudo -u $BUILD_USER -H -i sh -c "cd .BUILD && ./test_build.sh"

