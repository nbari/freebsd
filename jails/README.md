FreeBSD Jails
=============


Creating a jail with ZFS
========================

1. Chose the location and name.
-------------------------------

In this example, name will be 'sandbox' and location will be /tank/jails/sandbox

    # zfs create tank/jails/sandbox
    # zfs create tank/jails/sandbox/home
    # zfs create tank/jails/sandbox/tmp

Set a disk quota of 10GB to the full jail

    # zfs set quota=10G tank/jails/sandbox

2. Build the world for the jail.
--------------------------------

Set D with the location of our jail:

    # setenv D /tank/jails/sandbox
    # cd /usr/src

> shell used 'csh'

Build the world with your custom configuration (see the [src-jail.conf](src-jail.conf) or the man page: [src.conf](https://www.freebsd.org/cgi/man.cgi?query=src.conf)

    # make world DESTDIR=$D SRCCONF=/etc/src-jail.conf

if have multiple cores give a try to something like:

    # make -j40 world DESTDIR=$D SRCCONF=/etc/src-jail.conf

on AWS EC2 instance c3.8xlarge takes less than 10 min:
```sh
--------------------------------------------------------------
>>> make world completed on Thu Dec  3 11:23:27 UTC 2015
                   (started Thu Dec  3 11:14:03 UTC 2015)
--------------------------------------------------------------
```


If you have already compiled the world you can just install it:

    # make installworld DESTDIR=$D SRCCONF=/etc/src-jail.conf

Now is a good time to go pee or getting a coffee since this will take awhile,
basically this will create a new user land, compiling everything based on
your architecture and kernel.


> If you are running this remotely (ssh) try using tmux/screen so that you can
> close your session without need to wait the process to finish.  On a xen VM
> with 8 GB memory and 4 cores (CPU: Intel(R) Xeon(R) CPU E5-2630L 0 @2.00GHz
> (1995.24-MHz K8-class CPU)) it took:  2 hours, 47 minutes, 36 seconds to
> build/install the full world.

There are faster ways to do this but if performance and fine control is your
goal I will recommend this method, at the end, normally you will have to do it
only once (depends on your requirements).

3. The distribution target.
---------------------------

The distribution target for make installs every needed configuration file. In
simple words, it installs every installable file of /usr/src/etc/ to the /etc
directory of the jail environment: $D/etc/.

    # make distribution DESTDIR=$D SRCCONF=/etc/src-jail.conf

4. ports
--------

Share the ports from the main host to the jails:

    # mkdir $D/usr/ports
    # mkdir -p $D/var/ports/distfiles

Edit the jail /etc/make.conf and put something like:

    # cat $D/etc/make.conf
    NO_X= true
    WITHOUT_X11= yes
    OPTIONS_UNSET=X11
    WRKDIRPREFIX=/var/ports
    DISTDIR=/var/ports/distfiles
    PACKAGES=/var/ports/packages

5. jail rc.conf
---------------

Edit the jail rc.conf with some basic stuff like:

    # cat $D/etc/rc.conf
    hostname='your.jail.hostname'
    sshd_enable="YES"
    sshd_flags="-4"
    syslogd_flags="-ssC"
    clear_tmp_enable="YES"
    sendmail_enable="NONE"
    cron_flags="$cron_flags -J 60"
    salt_minion_enable="YES"

6. fstab
---------

The ports will be read only, so that you have to update only the ports on the
master and not in each jail, for this create the fstab on the host.

    # echo /usr/ports /tank/jails/sandbox/usr/ports nullfs ro 0 0 > /etc/fstab.sandbox
    # echo /usr/ports/distfiles /tank/jails/sandbox/var/ports/distfiles nullfs rw 0 0 >> /etc/fstab.sandbox

7. tmp permissions
------------------

Securing tmp in order to avoid executable or setuid files is a good idea, ZFS
helps to do that very easy.

    # zfs set setuid=off tank/jails/sandbox/tmp
    # zfs set exec=off tank/jails/sandbox/tmp


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


    base {
        jid = 100;
        name = base;
        host.hostname = $name.jail;
        ip4.addr = 10.15.129.100;
        path = /tank/jails/sandbox;
        mount.fstab = /etc/fstab.$name;
    }

Jail with ZFS:

    exec.start = "mount -t devfs devfs /dev; /bin/sh /etc/rc";
    exec.stop = "umount /dev; zfs umount -a; /bin/sh /etc/rc.shutdown";
    exec.clean;
    allow.mount;
    allow.mount.zfs;
    allow.mount.nullfs;
    allow.sysvipc;
    allow.raw_sockets;
    mount.devfs;
    enforce_statfs=1;
    securelevel=3;
    mount.fstab = "/etc/fstab.$name";
    host.hostname = "$name.jail";

    # Dynamic wildcard parameter:
    # Base the path off the jail name.
    path = "/tank/jails/$name";

    base {
        jid = 100;
        ip4.addr = 10.1.2.3;
    }

    playground {
        jid = 101;
        ip4.addr = 10.1.2.4;
        exec.poststart = "cpuset -c -l1-2 -j 101";
    }



Default user:

    pw useradd devops -m -s /bin/csh -G wheel




VNET
====

rc.conf:

```sh
cloned_interfaces="bridge0 epair0 epair1 epair2"
autobridge_interfaces="bridge0"
autobridge_bridge0="xn0 epair0a epair1a epair2a"
ifconfig_bridge0="up"
ifconfig_epair0a="up"
ifconfig_epair1a="up"
ifconfig_epair2a="up"
```

jail.conf:

```sh
exec.start = "/bin/sh /etc/rc.0";
exec.stop = "/bin/sh /etc/rc.shutdown";
exec.clean;
mount.devfs;
allow.raw_sockets;
securelevel =3;
host.hostname = "$name.jail";
path="/arena/jails/$name";

jail1 {
    jid = 1;
    vnet;
    vnet.interface = epair0b;
}
```

jail ``/etc/rc.0``:


```sh
#!/bin/sh

ifconfig lo0 127.0.0.1/8 up
sh /etc/rc

dhclient epair0b
```


Can't find free bpf
===================

To solve, add ``add path 'bpf*' unhide`` to ``/etc/defaults/devfs.rules``:

```sh
# Devices usually found in a jail.
#
[devfsrules_jail=4]
add include $devfsrules_hide_all
add include $devfsrules_unhide_basic
add include $devfsrules_unhide_login
add path zfs unhide
add path 'bpf*' unhide
```

To allow any user to open ports < 1024:

    net.inet.ip.portrange.reservedhigh=0


Kill the jail
=============

Starting jails: cannot start jail  "jail3":
jail: jail3: jail 3 already exists

    pkill -j 3


Postgresql
==========

In jail.conf add:

    allow.sysvipc;
