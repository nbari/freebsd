Install poudriere and qemu-user-static: pkg install poudriere qemu-user-static
Enable qemu-user-static in rc.conf: qemu_user_static_enable="YES"
Run the startup script to configure your system for building different architectures: /usr/local/etc/rc.d/qemu_user_static start
Create a ports tree to build: poudriere ports -c -m svn+https -p svn
Create an ARM build jail. Note, this will take awhile: poudriere jail -c -j 11armv6 -v head -a arm.armv6 -m svn+https
