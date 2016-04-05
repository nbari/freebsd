FreeBSD kernels
===============

Files listed here contain some kernels used for different environments as other configuration files.

Building and Installing a Custom Kernel in 3 simple steps
---------------------------------------------------------

1. Download the sources.

To get the lates **stable** sources you can do this:

    # svnlite co svn://svn.freebsd.org/base/stable/10 /usr/src

> At the time of writing this, the latest stable version is number 10.


2. Edit your kernel options.

Based on your requirements you may add or remove stuff. [The configuration file](https://www.freebsd.org/doc/en/books/handbook/kernelconfig-config.html)

    # cp /usr/src/sys/amd64/conf/GENERIC /home/tmp/my_custom_kernel

After editing your kernel, create a symlink to the same directory the GENERIC file was found, example:
    # cd /usr/src/sys/amd64/conf
    # ln -s /home/tmp/my_custom_kernel

The idea of coping the GENERIC to /home/tmp/my_custom_kernel, is that you don't delete your custom kernel accidentally while upgrading your sources (when doing a svn checkout)


3. Compile and install your kernel

This make time some time depending on your Hardware.

    # cd /usr/src
    # make kernel KERNCONF=YOUR_KERNEL_HERE

you can also edit the file /etc/make.conf and specify the kernel name, for example:

    # cat /etc/make.conf
    # KERNCONF=xen

And later only type:

    # make kernel


Reboot and hopefully your server will be up and running using your custom kernel.



Full update (fast way)
======================


1. ``cd /usr/src``
2. ``make buildworld``  (if have multiple cores you can try ``make -j40 buildworld``)
3. ``make kernel`` (or ``make -j40 kernel``)
4. ``make installworld`` (skip the mergemaster -p)
5. ``yes | make delete-old``
6. ``cp -R /etc /etc.old && cd /usr/src && make distribution DESTDIR=/``
7. ``cd /etc.old && cp group passwd master.passwd /etc && pwd_mkdb /etc/master.passwd``
8. ``reboot``
9. ``yes | make delete-old-libs``

> -j40 means to have up to 40 proccess running at any one time. (-j will cause ``make`` to spawn several simultaneous processes)


Using mergemaster
-----------------

After step 3 (before ``make installworld``) do:
```sh
mergemaster -p
make installworld
mergemaster -FiU
```


/usr/obj
--------

Save space removing the ``/usr/obj``:

     chflags -R noschg /usr/obj/*
     rm -rf /usr/obj


sysctl kern.conftxt
===================

Get kernel details


firstboot & firstboot-reboot
============================

To do some configuration at firstboot do a:

    touch /firstboot && touch /firstboot-reboot
