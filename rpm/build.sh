#!/bin/bash
DIR_BASE=$(cd ${BASH_SOURCE[0]%/*} && pwd)
RELEASE_VERSION=$1
SPEC_FILE=uacme.spec
if [ "$RELEASE_VERSION" == "" ]; then
  echo "First argument must be release version to compile"; exit 1
fi

set -e

if [ -f ".${SPEC_FILE}" ]; then
  unlink .${SPEC_FILE}
fi

cp ${SPEC_FILE}.template .${SPEC_FILE}
sed -i "s/__RELEASE_VERSION__/${RELEASE_VERSION}/g" .${SPEC_FILE}

rm -rf uacme uacme-${RELEASE_VERSION}
mkdir -p ~/rpmbuild/SOURCES
rm -rf ~/rpmbuild/SOURCES/uacme-${RELEASE_VERSION} uacme-${RELEASE_VERSION}
set -e

wget https://github.com/ndilieto/uacme/archive/v${RELEASE_VERSION}.tar.gz -O uacme-${RELEASE_VERSION}.tar.gz
mv uacme-${RELEASE_VERSION}.tar.gz ~/rpmbuild/SOURCES/

rpmbuild -bb .${SPEC_FILE}
set +e

rm -rf uacme uacme-${RELEASE_VERSION}
