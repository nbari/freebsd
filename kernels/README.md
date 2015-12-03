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
