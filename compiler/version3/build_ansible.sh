#!/bin/bash
DIR_BASE=$(cd ${BASH_SOURCE[0]%/*} && pwd)
RELEASE_VERSION=$1

DDIR=ansible-2.8.13

_REQUIRED_YUM_PACKAGES="rpm-build"
# sqlite-devel jansson-devel wget mariadb-devel zlib-devel libpcap-devel libtool libmaxminddb libmaxminddb-devel pkgconfig"
SPEC_FILE=ansible.spec


if [ "$RELEASE_VERSION" == "" ]; then
          echo "First argument must be release version to compile"; exit 1
fi

set -e


if [ -f ".${SPEC_FILE}" ]; then
      unlink .${SPEC_FILE}
fi

cp ${SPEC_FILE}.template .${SPEC_FILE}
sed -i "s/__RELEASE_VERSION__/${RELEASE_VERSION}/g" .${SPEC_FILE}

#sudo dnf -y install $_REQUIRED_YUM_PACKAGES

mkdir -p ~/rpmbuild/SOURCES
#wget https://github.com/binRick/ansible-bundle-playbook-dev/archive/master.zip -O ~/rpmbuild/SOURCES/ansible-bundle-playbook-${RELEASE_VERSION}.zip
cp ~/.xxx.tar.gz ~/rpmbuild/SOURCES/ansible-bundle-playbook-${RELEASE_VERSION}.tar.gz

if [[ "1" == "0" ]]; then

td=$(mktemp -d)
(
 cd $td
  (
    mkdir o
    cd o
    #unzip ~/rpmbuild/SOURCES/.tmp-ansible-bundle-playbook-${RELEASE_VERSION}.zip
    tar zxf ~/rpmbuild/SOURCES/.tmp-ansible-bundle-playbook-${RELEASE_VERSION}.tar.gz
    rm -rf .git
 )
 mkdir $DDIR
 mv o/* $DDIR
 tar -czf ~/rpmbuild/SOURCES/ansible-bundle-playbook-${RELEASE_VERSION}.tar.gz $DDIR
 pwd
# exit 100
)

fi


rpmbuild -bb .${SPEC_FILE}

source /etc/.ansi
ansi --green RPM Contains $(rpm -qpl ~/rpmbuild/RPMS/x86_64/ansible-${RELEASE_VERSION}-1.el7.x86_64.rpm | wc -l) Files
ansi --yellow $(rpm -qpl ~/rpmbuild/RPMS/x86_64/ansible-${RELEASE_VERSION}-1.el7.x86_64.rpm)


