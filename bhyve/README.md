Bhyve
=====

Create img:

    truncate -s 20g bhyve1.img

Install from iso:

    ./bhyve1.sh -i -I FreeBSD-10.0-RELEASE-amd64-dvd1.iso fbsd10X

Before rebooting edit /etc/ttys and add:

    console "/usr/libexec/getty std.9600"    xterm   on  secure

or:

    cat >> /etc/ttys << EOF
    console "/usr/libexec/getty std.9600"   vt100   on secure
    EOF

reboot to exit the loop script and to run the vm type:

    ./bhyve1.sh fbsd10X
