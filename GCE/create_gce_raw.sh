#!/bin/sh
# ----------------------------------------------------------------------------
# Create disk.raw, disk.tar.gz for Google Compute Engine
# ----------------------------------------------------------------------------
START=$(date +%s)

# ----------------------------------------------------------------------------
# options
# ----------------------------------------------------------------------------
OUTDIR=/gce
WRKDIR=${OUTDIR}/disk
SWAPSIZE=1G
VMSIZE=2g

# ----------------------------------------------------------------------------
# no need to change below this line
# ----------------------------------------------------------------------------
umount_loop() {
    DIR=$1
    i=0
    sync
    while ! umount ${DIR}; do
        i=$(( $i + 1 ))
        if [ $i -ge 10 ]; then
            # This should never happen.  But, it has happened.
            echo "Cannot umount(8) ${DIR}"
            echo "Something has gone horribly wrong."
            return 1
        fi
        sleep 1
    done

    return 0
}

VMBASE=${WRKDIR}.img
mkdir -p ${WRKDIR}
truncate -s ${VMSIZE} ${VMBASE}
mddev=$(mdconfig -f ${VMBASE})
newfs -U -j -t /dev/${mddev}
mount /dev/${mddev} ${WRKDIR}

cd /usr/src
make DESTDIR=${WRKDIR} installworld && make DESTDIR=${WRKDIR} installkernel
# make DESTDIR=${WRKDIR} world && make DESTDIR=${WRKDIR} kernel
make DESTDIR=${WRKDIR} distribution

mkdir -p ${WRKDIR}/dev
mount -t devfs devfs ${WRKDIR}/dev
chroot ${WRKDIR} /usr/bin/newaliases
chroot ${WRKDIR} /etc/rc.d/ldconfig forcestart
umount_loop ${WRKDIR}/dev

cp /etc/resolv.conf ${WRKDIR}/etc/resolv.conf

# install curl
echo " Installing curl"
yes | chroot ${WRKDIR} /usr/bin/env ASSUME_ALWAYS_YES=yes pkg install -qy curl > /dev/null 2>&1
chroot ${WRKDIR} /usr/bin/env ASSUME_ALWAYS_YES=yes pkg clean -qya > /dev/null 2>&1
rm -rf ${WRKDIR}/var/db/pkg/repo*

# devops-user
chroot ${WRKDIR} mkdir -p /usr/local/etc/rc.d
sed 's/^X//' >${WRKDIR}/usr/local/etc/rc.d/gce_metadata << 'GCE_METADATA'
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

chmod 0555 ${WRKDIR}/usr/local/etc/rc.d/gce_metadata

# fstab
cat << EOF > ${WRKDIR}/etc/fstab
/dev/gpt/rootfs   /       ufs     rw      1       1
/dev/gpt/swapfs   none    swap    sw      0       0
EOF

cat << EOF >> ${WRKDIR}/etc/hosts
169.254.169.254 metadata.google.internal metadata
EOF

cat << EOF > ${WRKDIR}/etc/ntp.conf
server metadata.google.internal iburst

restrict default kod nomodify notrap nopeer noquery
restrict -6 default kod nomodify notrap nopeer noquery

restrict 127.0.0.1
restrict -6 ::1
restrict 127.127.1.0
EOF

cat << EOF >> etc/syslog.conf
*.err;kern.warning;auth.notice;mail.crit                /dev/console
EOF

# rc.conf
echo 'gce_metadata_enable="YES"' > ${WRKDIR}/etc/rc.conf
echo 'growfs_enable="YES"' >> ${WRKDIR}/etc/rc.conf
echo 'ifconfig_DEFAULT="SYNCDHCP mtu 1460"' >> ${WRKDIR}/etc/rc.conf
echo 'sshd_enable="YES"' >> ${WRKDIR}/etc/rc.conf
echo 'ntpd_sync_on_start="YES"' >> ${WRKDIR}/etc/rc.conf
echo 'ntpd_enable="YES"' >> ${WRKDIR}/etc/rc.conf

# sysctl.conf
echo 'debug.trace_on_panic=1' >> ${WRKDIR}/etc/sysctl.conf
echo 'debug.debugger_on_panic=0' >> ${WRKDIR}/etc/sysctl.conf
echo 'kern.panic_reboot_wait_time=0' >> ${WRKDIR}/etc/sysctl.conf
echo 'net.inet.icmp.drop_redirect=1' >> ${WRKDIR}/etc/sysctl.conf
echo 'net.inet.ip.redirect=0' >> ${WRKDIR}/etc/sysctl.conf
echo 'net.inet.tcp.blackhole=2' >> ${WRKDIR}/etc/sysctl.conf
echo 'net.inet.udp.blackhole=1' >> ${WRKDIR}/etc/sysctl.conf
echo 'kern.ipc.somaxconn=1024' >> ${WRKDIR}/etc/sysctl.conf

# loader.conf
echo 'autoboot_delay="-1"' >> ${WRKDIR}/boot/loader.conf
echo 'beastie_disable="YES"' >> ${WRKDIR}/boot/loader.conf
echo 'loader_logo="none"' >> ${WRKDIR}/boot/loader.conf
echo 'console="comconsole"' >> ${WRKDIR}/boot/loader.conf
echo 'hw.broken_txfifo="1"' >> ${WRKDIR}/boot/loader.conf
echo 'hw.memtest.tests="0"' >> ${WRKDIR}/boot/loader.conf
echo 'hw.vtnet.mq_disable="1"' >> ${WRKDIR}/boot/loader.conf

# firstboot
touch ${WRKDIR}/firstboot

# cleanup
umount_loop /dev/${mddev}
rmdir ${WRKDIR}
tunefs -j enable /dev/${mddev}
mdconfig -d -u ${mddev}

# create raw
BOOTFILES=/usr/obj/usr/src/sys/boot
mkimg -s gpt -f raw \
    -b ${BOOTFILES}/i386/pmbr/pmbr \
    -p freebsd-boot/bootfs:=${BOOTFILES}/i386/gptboot/gptboot \
    -p freebsd-swap/swapfs::${SWAPSIZE} \
    -p freebsd-ufs/rootfs:=${VMBASE} \
    -o ${WRKDIR}.raw

echo "  Creating image tar"
cd ${OUTDIR}
tar --format=gnutar -Szcf disk.tar.gz disk.raw

END=$(date +%s)
DIFF=$(echo "$END - $START" | bc)

echo ----------------------------------------------------------------------------
echo "build in $DIFF seconds."
echo ----------------------------------------------------------------------------
