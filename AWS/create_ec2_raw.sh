#!/bin/sh
# Create ec2.raw for AMI

DESTDIR=/aws/ec2
VMBASE=${DESTDIR}.img
mkdir -p ${DESTDIR}
truncate -s 1536M ${VMBASE}
mddev=$(mdconfig -f ${VMBASE})
newfs /dev/${mddev}
mount /dev/${mmdev} ${DESTDIR}

cd /usr/src; make DESTDIR=${DESTDIR} installworld installkernel distribution

mkdir -p ${DESTDIR}/dev
mount -t devfs devfs ${DESTDIR}/dev
chroot ${DESTDIR} /usr/bin/newaliases
chroot ${DESTDIR} /etc/rc.d/ldconfig forcestart
umount_loop ${DESTDIR}/dev

cp /etc/resolv.conf ${DESTDIR}/etc/resolv.conf
# fstab
echo '# Custom /etc/fstab for FreeBSD VM images' > ${DESTDIR}/etc/fstab
echo '/dev/gpt/rootfs   /       ufs     rw      1       1'  >> ${DESTDIR}/etc/fstab
# rc.conf
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

# cleanup
umount_loop ${DESTDIR}
mdconfi -d -u ${mddev}

# create raw
BOOTFILES=/usr/obj/usr/src/sys/boot
mkimg -s gpt -f ${VMFORMAT} \
    -b ${BOOTFILES}/i386/pmbr/pmbr \
    -p freebsd-boot/bootfs:=${BOOTFILES}/i386/gptboot/gptboot \
    -p freebsd-ufs/rootfs:=${VMBASE} \
    -o ${VMBASE}.raw


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
