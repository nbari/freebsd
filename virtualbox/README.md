Create VM
---------

In this case FBSD10 is the name of the VM

    VBoxManage createvm --name FBSD10 --ostype FreeBSD_64 --register

Define memory, nic, tap:

    VBoxManage modifyvm FBSD10 --memory 4096 --ioapic on --cpus 4 --chipset ich9 --nic1 bridged --nictype1 82540EM --bridgeadapter1 tap0

Disk controller:

    VBoxManage storagectl FBSD10 --name "SATA Controller" --add sata --controller IntelAhci --portcount 8

Create a 10GB disk:

    VBoxManage createhd --filename freebsd10G.vdi --size 10240

Attach disk:

    VBoxManage storageattach FBSD10 --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium freebsd10G.vdi --nonrotational on --discard on

> --discard on helps to avoid erros when installing on SSD

Create a 1GB disk and attach it:

    VBoxManage createhd --filename d1 --size 2048
    VBoxManage storageattach FBSD10 --storagectl "SATA Controller" --port 1 --device 0 --type hdd --medium d1.vdi --nonrotational on

Install from iso:

    VBoxManage storagectl FBSD10 --name "IDE Controller" --add ide --controller PIIX4
    VBoxManage storageattach FBSD10 --storagectl "IDE Controller" --port 1 --device 0 --type dvddrive --medium FreeBSD.iso


Configure VNC:

    VBoxManage modifyvm FBSD10 --vrdeport 4901 --vrdeproperty  VNCPassword=your_password

Boot from disk (alter order):

    VBoxManage modifyvm FBSD10 --boot1 disk --boot2 dvd --boot3 none --boot4 none

Start the VM:

    VBoxHeadless --startvm FBSD10


Failed to open '/dev/tap0' for read/write access.
-------------------------------------------------

If you get a permission denied warning indicating to chmod 0666 /dev/tap0 device.

Edit /etc/devfs.conf

    own tap0 root:wheel
    perm tap0 0660


MODE_280
--------

In ``/etc/rc.local`` add:

    vidcontrol MODE_280

To know which mode you can be interested in:

    vidcontrol -i mode


RAW to VDI
----------

To use RAW images on Virtualbox:

    VBoxManage convertfromraw ec2.raw ec2.vdi --format VDI

resize raw disk:

    VBoxManage modifyhd ec2.vdi --resize 8192

To 100GB:

    VBoxManage modifyhd ec2.vdi --resize 10240
