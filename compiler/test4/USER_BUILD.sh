#!/bin/bash
set +e
[[ "$BUILD_USER" == "" ]] && export BUILD_USER="C3"
BUILD_DIR="/home/$BUILD_USER/.BUILD"


(sudo useradd $BUILD_USER) >/dev/null 2>&1
sudo rm -rf $BUILD_DIR
#sudo ls $BUILD_DIR >/dev/null 2>&1|| 
mkdir -p  $BUILD_DIR 
set -e

sudo rsync $(cat BUILD_FILES.txt) $BUILD_DIR/.

sudo chown -R $BUILD_USER:$BUILD_USER $BUILD_DIR/.


sudo -u $BUILD_USER -H -i sh -c "cd $BUILD_DIR/. && ./test_build.sh"

