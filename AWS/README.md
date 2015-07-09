FreeBSD on AWS EC2
==================

Build
-----

Edit [src.conf and your kernel](https://github.com/nbari/freebsd/tree/master/kernels) based on your needs:

    # cd /usr/src && make buildworld buildkernel

Create an image:

    # create_ec2_raw.sh

Import volume:

    # ec2-import-volume ec2.raw -f raw -z us-east-1a -b yourbucket -o AKIAJANL -w +YL8t2XaMRU

Create snapshot:

    # ec2-create-snapshot vol-5bd271b1 -d "freebsd test"

Delete volume:

    # ec2-delete-volume vol-5bd271b1

Register AMI:

    # ec2-register -n "FreeBSD test" -d "FreeBSD AWS test" -a x86_64 --virtualization-type hvm --root-device-name /dev/sda1 -b "/dev/sda1=snap-ed9cd29e:10:true:gp2" -b "/dev/sdb=ephemeral0" -b "/dev/sdc=ephemeral1" -b "/dev/sdd=ephemeral2" -b "/dev/sde=ephemeral3"
