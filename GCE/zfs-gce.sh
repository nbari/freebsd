#!/bin/sh
# ----------------------------------------------------------------------------
# Create disk.raw FreeBSD ZFS root
# ----------------------------------------------------------------------------
START=$(date +%s)
RAW=disk.raw
VMSIZE=2g
GH_USER=nbari # fetch keys from http://github.com/__user__.keys"

# ----------------------------------------------------------------------------
zpool list
truncate -s ${VMSIZE} ${RAW}
mddev=$(mdconfig -a -t vnode -f ${RAW})

gpart create -s gpt ${mddev}
gpart add -a 4k -s 512k -t freebsd-boot ${mddev}
gpart add -a 4k -t freebsd-swap -s 1G -l swap0 ${mddev}
gpart add -a 1m -t freebsd-zfs -l disk0 ${mddev}
gpart bootcode -b /boot/pmbr -p /boot/gptzfsboot -i 1 ${mddev}

sysctl vfs.zfs.min_auto_ashift=12

zpool create -o altroot=/mnt -o autoexpand=on -O compress=lz4 -O atime=off zroot /dev/gpt/disk0
zfs create -o mountpoint=none zroot/ROOT
zfs create -o mountpoint=/ zroot/ROOT/default
zfs create -o mountpoint=/tmp -o exec=off -o setuid=off zroot/tmp
zfs create -o mountpoint=/usr -o canmount=off zroot/usr
zfs create -o mountpoint=/usr/home zroot/usr/home
zfs create -o mountpoint=/usr/ports -o setuid=off zroot/usr/ports
zfs create zroot/usr/src
zfs create -o mountpoint=/var -o canmount=off zroot/var
zfs create -o exec=off -o setuid=off zroot/var/audit
zfs create -o exec=off -o setuid=off zroot/var/crash
zfs create -o exec=off -o setuid=off zroot/var/log
zfs create -o exec=off -o setuid=off -o readonly=on zroot/var/empty
zfs create -o atime=on zroot/var/mail
zfs create -o setuid=off zroot/var/tmp
zfs create zroot/var/ports
zfs create zroot/usr/obj
zpool set bootfs=zroot/ROOT/default zroot

cd /usr/src; make DESTDIR=/mnt installworld && \
    make DESTDIR=/mnt installkernel && \
    make DESTDIR=/mnt distribution

mkdir -p /mnt/dev
mount -t devfs devfs /mnt/dev
chroot /mnt /usr/bin/newaliases
chroot /mnt /etc/rc.d/ldconfig forcestart
umount /mnt/dev

# /etc/resolv.conf
cat << EOF > /mnt/etc/resolv.conf
nameserver 4.2.2.2
nameserver 8.8.8.8
nameserver 2001:4860:4860::8888
nameserver 2001:1608:10:25::1c04:b12f
EOF

# install curl
echo " Installing curl"
yes | chroot /mnt /usr/bin/env ASSUME_ALWAYS_YES=yes pkg install -qy curl > /dev/null 2>&1
chroot /mnt /usr/bin/env ASSUME_ALWAYS_YES=yes pkg clean -qya > /dev/null 2>&1
rm -rf /mnt/var/db/pkg/repo*

# devops-user
chroot /mnt mkdir -p /usr/local/etc/rc.d
sed 's/^X//' >/mnt/usr/local/etc/rc.d/gce_metadata << 'GCE_METADATA'
X#!/bin/sh
X
X# KEYWORD: firstboot
X# PROVIDE: gce_metadata
X# REQUIRE: NETWORKING
X# BEFORE: LOGIN
X
X# Define gce_metadata_enable=YES in /etc/rc.conf to enable SSH key fetching
X# when the system first boots.
X: ${gce_metadata_enable=NO}
X
X# Set gce_metadata_user to change the user for which SSH keys are provided.
X: ${gce_metadata_user=devops}
X
X. /etc/rc.subr
X
Xname="gce_metadata"
Xrcvar=gce_metadata_enable
Xstart_cmd="gce_metadata_run"
Xstop_cmd=":"
X
XSSHKEYURL="http://169.254.169.254/computeMetadata/v1/project/attributes/ssh-keys"
XSSHKEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDCu3MS7nQxGaOZJiU3Nq65JXRuggfRSPuhwqOD0r5Dcs2E9swP1enZVvHsadED0v+rOBmXPB5a9IJuTg71wB/rCmDLZ+UxOyA8DPfM/1wexM4qv7AI38lz1qb/pNePL/AcsHz5hxKJcYGdPY/Dpta0r2tcu9zp1540vfjfjFUftxoJ49fJ4UM5pQUBerhf1Vorl6uXt3wdJ3kZ45WU1lDRp5Nhi2BwngGa51kAylnO/IJkfYMj+nU7VgiMpNUj2KGbZRmhtKyPzKo8D2m4a9fS/vwjoZpG3Z5uB/HauzXz1vvWEG1EKSviYmd1u5kjHYPbjTjCtETfm6gWy8uRSQJP9ndYgp10z8qwlhTp3To0oOlkMKjzYNfMhit4/xNrusiD7yBJPtYf90ErPVnGmQhbeleSeAaoW26+5r+xJZPVzcESM1pt7dhqWMo6bCuwc7blPO0QiEwii2UBVWqFB7oHJEnQTsJ9exvfxDsFirVARFXjzocK1c6txF0zJ+hLbPuzTkJ/9iS9YlUBmQNWEDIAUHEpFievem/28bcRIkrdFQEku1L3PDq7EEUK3jkLl7Qo3/ONkZ+hBjriZ5HrmtOzeel6n8Qcq4b2wepWX+FgfpjP18c9peS9Dk2nvJ1tDmZifNrHreH6O+mvQDOxRp51B835Mn8L+/4NSww4tQbP0Q=="
X
Xgce_metadata_run()
X{
X	# If the user does not exist, create it.
X	if ! grep -q "^${gce_metadata_user}:" /etc/passwd; then
X		echo "Creating user ${gce_metadata_user}"
X		pw useradd ${gce_metadata_user} -m -G wheel -s /bin/csh
X	fi
X
X	# Figure out where the SSH public key needs to go.
X	eval SSHKEYFILE="~${gce_metadata_user}/.ssh/authorized_keys"
X
X	# Grab the provided SSH public key and add it to the
X	# right authorized_keys file to allow it to be used to
X	# log in as the specified user.
X	echo "Fetching SSH public key for ${gce_metadata_user}"
X	mkdir -p `dirname ${SSHKEYFILE}`
X	chmod 700 `dirname ${SSHKEYFILE}`
X	chown ${gce_metadata_user} `dirname ${SSHKEYFILE}`
X	/usr/local/bin/curl -s -H "Metadata-Flavor: Google" -f ${SSHKEYURL} -o ${SSHKEYFILE}.gce
X	if [ -f ${SSHKEYFILE}.gce ]; then
X		touch ${SSHKEYFILE}
X		sort -u ${SSHKEYFILE} ${SSHKEYFILE}.gce > ${SSHKEYFILE}.tmp
X		mv ${SSHKEYFILE}.tmp ${SSHKEYFILE}
X		chown ${gce_metadata_user} ${SSHKEYFILE}
X		rm ${SSHKEYFILE}.gce
X	else
X		echo "Fetching SSH public key failed!"
X	fi
X
X    echo ${SSHKEY} >> ${SSHKEYFILE}
X}
X
Xload_rc_config $name
Xrun_rc_command "$1"
GCE_METADATA

chmod 0555 /mnt/usr/local/etc/rc.d/gce_metadata
touch /mnt/firstboot

# /etc/fstab
cat << EOF > /mnt/etc/fstab
/dev/gpt/swap0   none    swap    sw      0       0
EOF

cat << EOF >> /mnt/etc/hosts
169.254.169.254 metadata.google.internal metadata
EOF

cat << EOF > /mnt/etc/ntp.conf
server metadata.google.internal iburst

restrict default kod nomodify notrap nopeer noquery
restrict -6 default kod nomodify notrap nopeer noquery

restrict 127.0.0.1
restrict -6 ::1
restrict 127.127.1.0
EOF

cat << EOF >> /mnt/etc/syslog.conf
*.err;kern.warning;auth.notice;mail.crit                /dev/console
EOF

# /boot/loader.conf
cat << EOF > /mnt/boot/loader.conf
autoboot_delay="-1"
beastie_disable="YES"
console="comconsole,vidconsole"
hw.broken_txfifo="1"
hw.memtest.test="0"
hw.vtnet.mq_disable="1"'
kern.geom.label.disk_ident.enable="0"
kern.geom.label.gptid.enable="0"
kern.timecounter.hardware=ACPI-safe'
loader_logo="none"
zfs_load="YES"
EOF

# /etc/rc.conf
cat << EOF > /mnt/etc/rc.conf
gce_metadata_enable="YES"
zfs_enable="YES"
ifconfig_DEFAULT="SYNCDHCP mtu 1460"
clear_tmp_enable="YES"
dumpdev="NO"
ntpd_enable="YES"
ntpd_sync_on_start="YES"
ntpdate_enable="YES"
sendmail_enable="NONE"
sshd_enable="YES"
syslogd_flags="-ssC"
EOF

# /etc/sysctl.conf
cat << EOF > /mnt/etc/sysctl.conf
debug.trace_on_panic=1
debug.debugger_on_panic=0
kern.panic_reboot_wait_time=0
security.bsd.see_other_uids=0
security.bsd.see_other_gids=0
security.bsd.unprivileged_read_msgbuf=0
security.bsd.unprivileged_proc_debug=0
security.bsd.stack_guard_page=1
EOF

zpool export zroot
mdconfig -d -u ${mddev}
chflags -R noschg /mnt
rm -rf /mnt/*

echo "  Creating image tar"
tar --format=gnutar -Szcf disk.tar.gz disk.raw

END=$(date +%s)
DIFF=$(echo "$END - $START" | bc)

echo ----------------------------------------------------------------------------
echo "build in $DIFF seconds."
echo ----------------------------------------------------------------------------
