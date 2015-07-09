#!/bin/sh
# ----------------------------------------------------------------------------
# Create ec2.raw for AMI
# ----------------------------------------------------------------------------

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

# nbari
NBARI="ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAgEArgnvK7DB4U2ZRUp/jAK+a2bz7Brni5WeUcdK9p8jATj5/zUjKdPLwPnl5DBWSLbKbuoL2S1ydyWQOzvC9pWdDXoEugkEORTwQamQprXcn3Y563fi1zmHJSVYEgphG/W2QUsyBl6TtMM7+8bQ15lHLeOoZDSnD5U0KvQpWHyvxO6zgzeCtPBQ0wS2Qli7Y4FltHx/sVhBUEUEIK/hWJhl3Kie3iGX8pt7x2/CPuhq9/5bEN3qzs9cMiEWtUnLYV09NMF16YngGFXRvIm1PzC4V2/qDJDGU3rZ8gAbwz+WoIJV1J9bOEqZLzoJKCvNGZcTCZ3ncwWaGkA2bGPoO1DfyP0KvgQwMPs8n0Ih8EG5pNeWjFAzuYV0d4sSw5gsDqeX9ym41t4cKoNgIzPbCDGD1kA7ouSQcXsBtZW0YCaG8ibV5yuacEeeL4vGDRs8EZ6pTAnb2CAerv0JGIwrOuDAGbRRKGssbIOvV/GTgSr8uA8QuiZVoBxSJFN7s3q30bR6Y0PAUulV+zEt2n6PL7ovcrm63ibe2G1hUQ8EcPbW3KpQfj28XpGwDS4X6FYEn0MO+F5iOcqhOn6fQWbD/GA5b8umUskJbJi8m28xU+J49f+TnHH+OX++MNdiPuiet5QVklJ4whazKAd0BPljZVaaU3J+1rI5/Hj1rnJcCUYTm/M="
chroot ${DESTDIR} /usr/sbin/pw useradd nbari -m -G wheel
chroot ${DESTDIR} mkdir -m 700 ~nbari/.ssh
echo ${NBARI} > ${DESTDIR}/home/nbari/.ssh/authorized_keys
chroot ${DESTDIR} chown -R nbari ~nbari/.ssh

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
