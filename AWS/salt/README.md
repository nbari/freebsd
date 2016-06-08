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
