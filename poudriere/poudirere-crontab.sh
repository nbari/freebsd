#!/bin/sh

#  update pkg jails
# 30       1      *       *       *       root    /poudriere-crontab

JAILNAME=$1
PORTSTREE=$2

POUDRIERE_DIR="/usr/local/etc/poudriere.d/"

PATH="$PATH:/usr/local/bin"

if [ -z "$JAILNAME" ]; then
    printf "Provide a jail name please.\n"
    exit 1
fi

if [ -z "$PORTSTREE" ]; then
    PORTSTREE="default"
fi

# check that the ports tree exists
poudriere ports -l | grep "^$PORTSTREE" > /dev/null
if [ $? -gt 0 ]; then
    printf "No such ports tree ($PORTSTREE)\n"
    exit 2
fi

## check that there's a list of packages for that jail
if [ ! -f "$POUDRIERE_DIR$JAILNAME.pkglist" ]; then
    printf "No such file (list of packages: $POUDRIERE_DIR$PORTSTREE)\n"
    exit 3
fi

# check that the jail is there
poudriere jails -l | grep "^$JAILNAME" > /dev/null
if [ $? -gt 0 ]; then
    printf "No such jail ($JAILNAME)\n"
    exit 4
fi

# update the ports tree
poudriere ports -u -p $PORTSTREE

# build new packages
poudriere bulk -f /usr/local/etc/poudriere.d/$JAILNAME.pkglist -j $JAILNAME -p $PORTSTREE
