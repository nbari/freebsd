FreeBSD on AWS EC2
==================

Build
-----

Edit [src.conf and your kernel](https://github.com/nbari/freebsd/tree/master/kernels) based on your needs:

    # cd /usr/src && make -j36 buildworld buildkernel

Using a ``c4.8xlarge`` instance (36 cores) takes aproximately 0:06:29 h:m:s

Using a ``m4.16xlarge`` instance (64 cores) takes aproximately 0:12:53 (h:m:s):


> adjust -jXX based on the cpu cores

Create an image:

    # create_ec2_raw.sh


Import volume:

    # ec2-import-volume ec2.raw -f raw -z us-east-1a -b yourbucket -o AKIAJANL -w +YL8t2XaMRU

> CLI tools required for this: http://docs.aws.amazon.com/AWSEC2/latest/CommandLineReference/set-up-ec2-cli-linux.html#tools-introduction

> use -O, --aws-access-key if your are not the owner of the bucket

Wait until status is complete to get the volname

    # ec2-describe-conversion-tasks

Create snapshot:

    # ec2-create-snapshot vol-5bd271b1 -d "freebsd test"

Delete volume:

    # ec2-delete-volume vol-5bd271b1

Register AMI:

    # ec2-register -n "FreeBSD test" -d "FreeBSD AWS test" -a x86_64 --virtualization-type hvm --root-device-name /dev/sda1 -b "/dev/sda1=snap-ed9cd29e:10:true:gp2" -b "/dev/sdb=ephemeral0" -b "/dev/sdc=ephemeral1" -b "/dev/sdd=ephemeral2" -b "/dev/sde=ephemeral3"


#  Amazon EC2 CLI

More info: http://docs.aws.amazon.com/AWSEC2/latest/CommandLineReference/set-up-ec2-cli-linux.html

To install:

    fetch http://s3.amazonaws.com/ec2-downloads/ec2-api-tools.zip

or
    curl -O http://s3.amazonaws.com/ec2-downloads/ec2-api-tools.zip


Unzip the files into a suitable installation directory, such as /usr/local/ec2.

    mkdir /usr/local/ec2
    unzip ec2-api-tools.zip -d /usr/local/ec2
