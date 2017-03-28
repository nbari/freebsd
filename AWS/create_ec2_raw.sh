#!/bin/sh
# ----------------------------------------------------------------------------
# Create ec2.raw for amazon EC2 AMI
# ----------------------------------------------------------------------------
START=$(date +%s)

DESTDIR=/aws/ec2

SWAPSIZE=1G
VMSIZE=2g
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

VMBASE=${DESTDIR}.img
mkdir -p ${DESTDIR}
truncate -s ${VMSIZE} ${VMBASE}
mddev=$(mdconfig -f ${VMBASE})
newfs /dev/${mddev}
mount /dev/${mddev} ${DESTDIR}

cd /usr/src; make DESTDIR=${DESTDIR} installworld && \
make DESTDIR=${DESTDIR} installkernel && \
make DESTDIR=${DESTDIR} distribution

mkdir -p ${DESTDIR}/dev
mount -t devfs devfs ${DESTDIR}/dev
chroot ${DESTDIR} /usr/bin/newaliases
chroot ${DESTDIR} /etc/rc.d/ldconfig forcestart
umount_loop ${DESTDIR}/dev

cp /etc/resolv.conf ${DESTDIR}/etc/resolv.conf

# devops-user
chroot ${DESTDIR} mkdir -p /usr/local/etc/rc.d
sed 's/^X//' >${DESTDIR}/usr/local/etc/rc.d/ec2_fetchkey << 'EC2_FETCHKEY'
X#!/bin/sh
X
X# KEYWORD: firstboot
X# PROVIDE: ec2_fetchkey
X# REQUIRE: NETWORKING
X# BEFORE: LOGIN
X
X# Define ec2_fetchkey_enable=YES in /etc/rc.conf to enable SSH key fetching
X# when the system first boots.
X: ${ec2_fetchkey_enable=NO}
X
X# Set ec2_fetchkey_user to change the user for which SSH keys are provided.
X: ${ec2_fetchkey_user=devops}
X
X. /etc/rc.subr
X
Xname="ec2_fetchkey"
Xrcvar=ec2_fetchkey_enable
Xstart_cmd="ec2_fetchkey_run"
Xstop_cmd=":"
X
XSSHKEYURL="http://169.254.169.254/1.0/meta-data/public-keys/0/openssh-key"
XSSHKEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPa0/+4/WfcyGQ7rO0rnDkwa2XabWX1qpYrNOTttcyrv"
X
Xec2_fetchkey_run()
X{
X	# If the user does not exist, create it.
X	if ! grep -q "^${ec2_fetchkey_user}:" /etc/passwd; then
X		echo "Creating user ${ec2_fetchkey_user}"
X		pw useradd ${ec2_fetchkey_user} -m -G wheel
X	fi
X
X	# Figure out where the SSH public key needs to go.
X	eval SSHKEYFILE="~${ec2_fetchkey_user}/.ssh/authorized_keys"
X
X	# Grab the provided SSH public key and add it to the
X	# right authorized_keys file to allow it to be used to
X	# log in as the specified user.
X	echo "Fetching SSH public key for ${ec2_fetchkey_user}"
X	mkdir -p `dirname ${SSHKEYFILE}`
X	chmod 700 `dirname ${SSHKEYFILE}`
X	chown ${ec2_fetchkey_user} `dirname ${SSHKEYFILE}`
X	ftp -o ${SSHKEYFILE}.ec2 -a ${SSHKEYURL} >/dev/null
X	if [ -f ${SSHKEYFILE}.ec2 ]; then
X		touch ${SSHKEYFILE}
X		sort -u ${SSHKEYFILE} ${SSHKEYFILE}.ec2		\
X		    > ${SSHKEYFILE}.tmp
X		mv ${SSHKEYFILE}.tmp ${SSHKEYFILE}
X		chown ${ec2_fetchkey_user} ${SSHKEYFILE}
X		rm ${SSHKEYFILE}.ec2
X	else
X		echo "Fetching SSH public key failed!"
X	fi
X
X    echo ${SSHKEY} >> ${SSHKEYFILE}
X}
X
Xload_rc_config $name
Xrun_rc_command "$1"
EC2_FETCHKEY

chmod 0555 ${DESTDIR}/usr/local/etc/rc.d/ec2_fetchkey

# fstab
cat << EOF > ${DESTDIR}/etc/fstab
/dev/gpt/rootfs   /       ufs     rw      1       1
/dev/gpt/swapfs   none    swap    sw      0       0
EOF

# rc.conf
echo 'ec2_fetchkey_enable="YES"' > ${DESTDIR}/etc/rc.conf
echo 'growfs_enable="YES"' >> ${DESTDIR}/etc/rc.conf
echo 'ifconfig_DEFAULT="SYNCDHCP -tso"' >> ${DESTDIR}/etc/rc.conf
echo 'clear_tmp_enable="YES"' >> ${DESTDIR}/etc/rc.conf
echo 'syslogd_flags="-ssC"' >> ${DESTDIR}/etc/rc.conf
echo 'sendmail_enable="NONE"' >> ${DESTDIR}/etc/rc.conf
echo 'sshd_enable="YES"' >> ${DESTDIR}/etc/rc.conf
echo 'ntpdate_enable="YES"' >> ${DESTDIR}/etc/rc.conf
echo 'ntpd_enable="YES"' >> ${DESTDIR}/etc/rc.conf
echo 'dumpdev="NO"' >> ${DESTDIR}/etc/rc.conf

# sysctl.conf
echo 'debug.trace_on_panic=1' >> ${DESTDIR}/etc/sysctl.conf
echo 'debug.debugger_on_panic=0' >> ${DESTDIR}/etc/sysctl.conf
echo 'kern.panic_reboot_wait_time=0' >> ${DESTDIR}/etc/sysctl.conf
echo 'security.bsd.see_other_uids=0' >> ${DESTDIR}/etc/sysctl.conf
echo 'security.bsd.see_other_gids=0' >> ${DESTDIR}/etc/sysctl.conf
echo 'security.bsd.unprivileged_read_msgbuf=0' >> ${DESTDIR}/etc/sysctl.conf
echo 'security.bsd.unprivileged_proc_debug=0' >> ${DESTDIR}/etc/sysctl.conf
echo 'security.bsd.stack_guard_page=1' >> ${DESTDIR}/etc/sysctl.conf

# loader.conf
echo 'autoboot_delay="-1"' >> ${DESTDIR}/boot/loader.conf
echo 'beastie_disable="YES"' >> ${DESTDIR}/boot/loader.conf
echo 'console="comconsole"' >> ${DESTDIR}/boot/loader.conf
echo 'hw.broken_txfifo="1"' >> ${DESTDIR}/boot/loader.conf

# firstboot
touch ${DESTDIR}/firstboot

# cleanup
umount_loop /dev/${mddev}
rmdir ${DESTDIR}
tunefs -j enable /dev/${mddev}
mdconfig -d -u ${mddev}

# create raw
BOOTFILES=/usr/obj/usr/src/sys/boot
mkimg -s gpt -f raw \
    -b ${BOOTFILES}/i386/pmbr/pmbr \
    -p freebsd-boot/bootfs:=${BOOTFILES}/i386/gptboot/gptboot \
    -p freebsd-swap/swapfs::${SWAPSIZE} \
    -p freebsd-ufs/rootfs:=${VMBASE} \
    -o ${DESTDIR}.raw

mkimg -s gpt -f vmdk \
    -b ${BOOTFILES}/i386/pmbr/pmbr \
    -p freebsd-boot/bootfs:=${BOOTFILES}/i386/gptboot/gptboot \
    -p freebsd-swap/swapfs::${SWAPSIZE} \
    -p freebsd-ufs/rootfs:=${VMBASE} \
    -o ${DESTDIR}.vmdk

END=$(date +%s)
DIFF=$(echo "$END - $START" | bc)

echo ----------------------------------------------------------------------------
echo "build in $DIFF seconds."
echo ----------------------------------------------------------------------------
