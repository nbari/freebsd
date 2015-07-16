#!/bin/sh
# ----------------------------------------------------------------------------
# Create ec2.raw for amazon EC2 AMI
# ----------------------------------------------------------------------------
START=$(date +%s)

DESTDIR=/aws/ec2

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
# truncate -s 1536M ${VMBASE}
truncate -s 512M ${VMBASE}
mddev=$(mdconfig -f ${VMBASE})
newfs /dev/${mddev}
mount /dev/${mddev} ${DESTDIR}

cd /usr/src; make DESTDIR=${DESTDIR} installworld installkernel distribution

mkdir -p ${DESTDIR}/dev
mount -t devfs devfs ${DESTDIR}/dev
chroot ${DESTDIR} /usr/bin/newaliases
chroot ${DESTDIR} /etc/rc.d/ldconfig forcestart
umount_loop ${DESTDIR}/dev

cp /etc/resolv.conf ${DESTDIR}/etc/resolv.conf

# devops user
SSHKEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDCu3MS7nQxGaOZJiU3Nq65JXRuggfRSPuhwqOD0r5Dcs2E9swP1enZVvHsadED0v+rOBmXPB5a9IJuTg71wB/rCmDLZ+UxOyA8DPfM/1wexM4qv7AI38lz1qb/pNePL/AcsHz5hxKJcYGdPY/Dpta0r2tcu9zp1540vfjfjFUftxoJ49fJ4UM5pQUBerhf1Vorl6uXt3wdJ3kZ45WU1lDRp5Nhi2BwngGa51kAylnO/IJkfYMj+nU7VgiMpNUj2KGbZRmhtKyPzKo8D2m4a9fS/vwjoZpG3Z5uB/HauzXz1vvWEG1EKSviYmd1u5kjHYPbjTjCtETfm6gWy8uRSQJP9ndYgp10z8qwlhTp3To0oOlkMKjzYNfMhit4/xNrusiD7yBJPtYf90ErPVnGmQhbeleSeAaoW26+5r+xJZPVzcESM1pt7dhqWMo6bCuwc7blPO0QiEwii2UBVWqFB7oHJEnQTsJ9exvfxDsFirVARFXjzocK1c6txF0zJ+hLbPuzTkJ/9iS9YlUBmQNWEDIAUHEpFievem/28bcRIkrdFQEku1L3PDq7EEUK3jkLl7Qo3/ONkZ+hBjriZ5HrmtOzeel6n8Qcq4b2wepWX+FgfpjP18c9peS9Dk2nvJ1tDmZifNrHreH6O+mvQDOxRp51B835Mn8L+/4NSww4tQbP0Q=="
chroot ${DESTDIR} /usr/sbin/pw useradd devops -m -G wheel -s /bin/csh
chroot ${DESTDIR} mkdir -m 700 ~devops/.ssh
echo ${SSHKEY} > ${DESTDIR}/home/devops/.ssh/authorized_keys
chroot ${DESTDIR} chown -R devops ~devops/.ssh

# ec2-user
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
X: ${ec2_fetchkey_user=ec2-user}
X
X. /etc/rc.subr
X
Xname="ec2_fetchkey"
Xrcvar=ec2_fetchkey_enable
Xstart_cmd="ec2_fetchkey_run"
Xstop_cmd=":"
X
XSSHKEYURL="http://169.254.169.254/1.0/meta-data/public-keys/0/openssh-key"
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
X}
X
Xload_rc_config $name
Xrun_rc_command "$1"
EC2_FETCHKEY

chmod 0555 ${DESTDIR}/usr/local/etc/rc.d/ec2_fetchkey

# fstab
echo '/dev/gpt/rootfs   /       ufs     rw      1       1'  > ${DESTDIR}/etc/fstab

# rc.conf
echo 'ec2_fetchkey_enable="YES"' > ${DESTDIR}/etc/rc.conf
echo 'growfs_enable="YES"' >> ${DESTDIR}/etc/rc.conf
echo 'ifconfig_DEFAULT="SYNCDHCP"' >> ${DESTDIR}/etc/rc.conf
echo 'sshd_enable="YES"' >> ${DESTDIR}/etc/rc.conf

# sysctl.conf
echo 'debug.trace_on_panic=1' >> ${DESTDIR}/etc/sysctl.conf
echo 'debug.debugger_on_panic=0' >> ${DESTDIR}/etc/sysctl.conf
echo 'kern.panic_reboot_wait_time=0' >> ${DESTDIR}/etc/sysctl.conf

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
    -p freebsd-ufs/rootfs:=${VMBASE} \
    -o ${DESTDIR}.raw

END=$(date +%s)
DIFF=$(echo "$END - $START" | bc)

echo ----------------------------------------------------------------------------
echo "build in $DIFF seconds."
echo ----------------------------------------------------------------------------
