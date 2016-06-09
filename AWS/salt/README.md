# Image to be use with salt


Requirements

* awscli
* curl
* python
* vim
* salt
* iperf

Install them:

    pkg install awscli curl python vim-lite sudo py27-salt iperf


Configure the minion ``cat /usr/local/etc/minion``:

    startup_states: highstate
    mine_functions:
      test.ping: []
      network.ip_addrs:
        cidr: '10.0.0.0/16'

# AMI user
Create a AMI user to read-only for example: **vpc-readonly** and use this policy:

    {
        "Version": "2012-10-17",
        "Statement": [{
            "Sid": "1",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeTags"
            ],
            "Resource": [
                "*"
            ]
        }]
    }


Configure ``/etc/rc.conf`` to **firstboot** custom scripts:

    firstboot_sentinel="/firstboot"
    # you can omit ec2_fetchkey if keys already exists
    ec2_fetchkey_enable="YES"
    set_hostname_enable="YES"
    growfs_enable="YES"
    ifconfig_DEFAULT="SYNCDHCP -tso"
    salt_minion_enable="YES"

copy [set_hostname](https://github.com/nbari/freebsd/blob/master/AWS/salt/set_hostname)
to ``/usr/local/etc/rc.d/set_hostname``.

# firstboot

Before cloning the instance do:

    touch /firstboot

If need to reboot:

    touch /firstboot && touch /firstboot-reboot
