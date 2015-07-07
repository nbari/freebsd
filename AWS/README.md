FreeBSD on AWS EC2
==================

Install bsdec2-image-upload:

    # pkg install bsdec2-image-upload

or

    # cd /usr/ports/net/bsdec2-image-upload; make install clean


AWS setup
---------

1. Create an S3 bucket in the region you want to use the AMI (freebsd-yourname)
2. Create AWS Access Keys for the IAM user, and create a file in the format:

    ACCESS_KEY_ID=AKIEXAMPLEEXAMPLE
    ACCESS_KEY_SECRET=EXAMPLEEXAMPLEEXAMPLEEXAMPLEEXAMPLE


Make sure there isn't any errant whitespace in the key file, because the
`bsdec2-image-upload` tool isn't smart enough to remove it.


Build
-----

Fine tune your kernel, world and later:

    # cd /usr/src && make buildworld buildkernel

For AWS:

    # cd /usr/src/release && make WITH_CLOUDWARE=YES \
    AWSKEYFILE=/root/aws.key AWSREGION=eu-west-1 \
    AWSBUCKET=freebsd-yourname EC2PUBLIC=YES ec2ami

> Omit EC2PUBLIC=YES if you just want to create a private AMI in a single EC2 region.

Import volume:

    # ec2-import-volume ec2.raw -f raw -b freebsd-yourname

Create snapshot:

    # ec2-create-snapshot vol-5bd271b1 -d "freebsd test"

Register AMI:

    # ec2-register -n "FreeBSD test" -d "FreeBSD AWS test" -a x86_64 --virtualization-type hvm --root-device-name /dev/sda1 -b "/dev/sda1=snap-ed9cd29e:10:false:gp2" -b "/dev/sdb=ephemeral0" -b "/dev/sdc=ephemeral1" -b "/dev/sdd=ephemeral2" -b "/dev/sde=ephemeral3"
