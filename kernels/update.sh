#!/bin/sh
FREEBSD_VERSION=12
NUMBER_OF_CORES=`sysctl -n hw.ncpu`
ZPOOL="tank"

svnlite co svn://svn.freebsd.org/base/stable/${FREEBSD_VERSION} /usr/src

cd /usr/src

make -j${NUMBER_OF_CORES} buildworld
make -j${NUMBER_OF_CORES} kernel

zfs set exec=on ${ZPOOL}/tmp

make installworld
cp -R /etc /etc.old && cd /usr/src && make distribution DESTDIR=/
cd /etc.old && cp group passwd master.passwd /etc && pwd_mkdb /etc/master.passwd
cp /etc.old/ssh/sshd_config /etc/ssh/


echo "rebot and yes | make delete-old-libs"
