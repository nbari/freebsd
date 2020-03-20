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

write() {
    echo -e '\e[0;32m'
    echo \#----------------------------------------------------------------------------
    echo \# $1
    echo -e \#----------------------------------------------------------------------------'\e[0m'
}


cd /usr/src

write "Checking out and updating sources FreeBSD: ${FREEBSD_VERSION}"
svnlite co svn://svn.freebsd.org/base/stable/${FREEBSD_VERSION} /usr/src

# Exit immediately if a command exits with a non-zero exit status
set -e

write "building world"
make -j${NUMBER_OF_CORES} buildworld

write "building kernel"
make -j${NUMBER_OF_CORES} kernel

zfs set exec=on ${ZPOOL}/tmp

write "installing world"
make installworld


write "making distribution"
cp -R /etc /etc.old && cd /usr/src && make distribution DESTDIR=/

write "backup /etc"
(cd /etc.old && cp group passwd master.passwd /etc && pwd_mkdb /etc/master.passwd)
cp /etc.old/ssh/sshd_config /etc/ssh/

write "deleting old"
make -DBATCH_DELETE_OLD_FILES delete-old

END=$(date +%s)
DIFF=$(echo "$END - $START" | bc)
ELAPSED=$(printf '%02dh:%02dm:%02ds\n' $(($DIFF/3600)) $(($DIFF%3600/60)) $(($DIFF%60)))

write "Done in: $ELAPSED, rebot and then \"yes | make delete-old-libs\""
