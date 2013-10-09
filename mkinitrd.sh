#!/bin/bash

set -x

INITRD_ORIG=$1
INITRD_CUSTOM=/home/users/hcartiaux/viridis-initrd-customized.gz

WORKDIR=/tmp/cpio
CURRENT=`pwd`

mkdir -p $WORKDIR
cd       $WORKDIR

gzip -dc $INITRD_ORIG | cpio -i

cp $CURRENT/files/iscsistart sbin/
cp $CURRENT/files/init .

find . | cpio -H newc -o | gzip > $INITRD_CUSTOM

echo "=== OUTPUT ==="
echo "Initrd custom: ${INITRD_CUSTOM}"

