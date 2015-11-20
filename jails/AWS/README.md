FreeBSD Jails on AWS
====================

4 IP's, 2 ENI, 1 t2.micro (multiple routing tables / Asymmetric routing):

DHCP / alias setup on ``/etc/rc.conf``:

    ifconfig_xn0="SYNCDHCP fib 0"
    ifconfig_xn0_alias0="inet 10.0.10.X netmask 255.255.255.255"
    ifconfig_xn1="SYNCDHCP fib 1"
    ifconfig_xn1_alias0="inet 10.0.10.X netmask 255.255.255.255"


Append to  ``/etc/rc.local``  for adding the route:

    setfib 1 route add default 10.0.X.1


Append to  ``/etc/sysctl.conf`` must contain:

    net.add_addr_allfibs=0


jail rc.conf
------------

Edit the jail rc.conf with some basic stuff like:

    # cat $D/etc/rc.conf
    hostname='your.jail.hostname'
    sshd_enable="YES"
    sshd_flags="-4"
    syslogd_flags="-ssC"
    clear_tmp_enable="YES"
    sendmail_enable="NONE"
    cron_flags="$cron_flags -J 60"

A basic jail setup on the host
==============================

One you have created the jail you need to configure the host in order to load the jail, a basic example is here:

    # cat /etc/jail.conf

    exec.start = "/bin/sh /etc/rc";
    exec.stop = "/bin/sh /etc/rc.shutdown";
    exec.clean;
    mount.devfs;
    allow.raw_sockets;
    securelevel =3;
    host.hostname = "$name.jail";
    path="/arena/jails/$name";

    jail1 {
        jid = 1;
        ip4.addr = 10.0.10.XXX;
         exec.fib = 1;
    }

> notice the exec.fib = 1;

on ``/etc/rc.conf`` append:

    jail_enable="YES"
    jail_list="jail1"

Please note if you use **jexec** to enter the jail you will be tricked into
executing everything with the wrong fib!
When the jail is launched and things automatically start they will use the
correct fib, but if you jexec into the jail and run things from the shell it
will not use the correct fib unless you setfib -F1 jexec when entering the jail!

When in doubt, check your fib with **sysctl net.my_fibnum**
