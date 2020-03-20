#!/bin/sh
FREEBSD_VERSION=12
NUMBER_OF_CORES=`sysctl -n hw.ncpu`
ZPOOL="tank"
START=$(date +%s)

if [ `sysctl -n kern.securelevel` -gt 0 ]; then
    sysrc kern_securelevel_enable="NO"
    echo "need to reboot with securelevel 0"
    exit
fi


cd /usr/src

svnlite co svn://svn.freebsd.org/base/stable/${FREEBSD_VERSION} /usr/src

# Exit immediately if a command exits with a non-zero exit status
set -e

make -j${NUMBER_OF_CORES} buildworld
make -j${NUMBER_OF_CORES} kernel

zfs set exec=on ${ZPOOL}/tmp

make installworld
cp -R /etc /etc.old && cd /usr/src && make distribution DESTDIR=/
cd /etc.old && cp group passwd master.passwd /etc && pwd_mkdb /etc/master.passwd
cp /etc.old/ssh/sshd_config /etc/ssh/
make -DBATCH_DELETE_OLD_FILES delete-old

END=$(date +%s)
DIFF=$(echo "$END - $START" | bc)
ELAPSED=$(printf '%02dh:%02dm:%02ds\n' $(($DIFF/3600)) $(($DIFF%3600/60)) $(($DIFF%60)))

echo "Done in: $ELAPSED, rebot and then \"yes | make delete-old-libs\""
