#!/bin/sh

RAW=disk.raw
VMSIZE=1g

truncate -s ${VMSIZE} ${RAW}
mddev=$(mdconfig -a -t vnode -f ${RAW})

gpart create -s gpt /dev/${mddev}
gpart add -b 40 -s 1024 -t freebsd-boot /dev/${mddev}
gpart add -t freebsd-zfs -l disk0 /dev/${mddev}
gpart bootcode -b /boot/pmbr -p /boot/gptzfsboot -i 1 /dev/${mddev}

# sysctl vfs.zfs.min_auto_ashift=12
zpool create -o cachefile=/var/tmp/zpool.cache -o altroot=/mnt -O compress=lz4 -O atime=off -O utf8only=on zroot /dev/gpt/disk0
zfs create -o mountpoint=none zroot/ROOT
zfs create -o mountpoint=/ zroot/ROOT/default
zfs create -o mountpoint=/tmp -o exec=on -o setuid=off zroot/tmp
zfs create -o mountpoint=/usr -o canmount=off zroot/usr
zfs create -o mountpoint=/usr/home zroot/usr/home
zfs create -o mountpoint=/usr/ports -o setuid=off zroot/usr/ports
zfs create zroot/usr/src
zfs create -o mountpoint=/var -o canmount=off zroot/var
zfs create -o exec=off -o setuid=off zroot/var/audit
zfs create -o exec=off -o setuid=off zroot/var/crash
zfs create -o exec=off -o setuid=off zroot/var/log
zfs create -o atime=on zroot/var/mail
zfs create -o setuid=off zroot/var/tmp
zfs create zroot/var/ports
zfs create zroot/usr/obj
zpool set bootfs=zroot/ROOT/default zroot

cd /usr/src
make DESTDIR=/zroot installworld && make DESTDIR=/zroot installkernel
make DESTDIR=/zroot distribution

cp /var/tmp/zpool.cache /zroot/boot/
cp /var/tmp/zpool.cache /zroot/boot/zfs/zpool.cache

# loader.conf
cat << EOF > /zroot/boot/loader.conf
#kern.geom.label.disk_ident.enable="0"
#kern.geom.label.gptid.enable="0"
#kern.geom.label.gpt.enable="1"
zfs_load="YES"
vfs.root.mountfrom="zfs:zroot/ROOT/default"
EOF

# rc.conf
cat << EOF > /zroot/etc/rc.conf
zfs_enable="YES"
ifconfig_DEFAULT="SYNCDHCP"
sshd_enable="YES"
ntpd_enable="YES"
EOF

#zpool export zroot
#mdconfig -d -u ${mddev}
