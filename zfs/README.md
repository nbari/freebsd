ZFS
===

Backup /tank to another server vis ssh:

> Now, here comes a big "gotcha". You now have to set the "readonly" attribute on the slave. I discovered that if this was not set, even just cd-ing into the slave’s mountpoints would cause things to break in subsequent replication operations; presumably down to metadata (access times and the like) being altered.

On the server that will receive the backup:

    zfs create zroot/backup/tank
    zfs set readonly=on zroot/backup/tank

Create the snapshot:

    zfs snapshot -r tank@25-01-2014

> `-r` for recursive

Send it via ssh + bzip2

    zfs send -Rv tank/dataset@25-01-2014 | bzip2 -c | ssh sever.tld "bzcat | zfs recv -F zroot/backup/tank"


Destroy all snapshots:

    foreach i ( `zfs list -H -t snapshot | cut -f 1` )
    foreach? zfs destroy $i
    foreach? end

One-liner:

    zfs list -H -o name -t snapshot | xargs -n1 zfs destroy

Send snapshot to file:

    zfs send -Rv tank/jails/base@25-01-2014 | bzip2 > tank_backup.bz2

Receive snapshot from a file:

    bzip2 -c -d tank_backup.bz2 | zfs receive -F zroot/backup/tank

RAID 1+0 (10)

    zpool create tank mirror ada1 ada2 mirror ada3 ada4

Adding Devices to a Storage Pool

    zpool add tank mirror ada5 ada6


To convert the raidz1-0 to raid 1+0 (striped-mirror):
-----------------------------------------------------

zpool status:

     pool: tank
    state: ONLINE
     scan: none requested
    config:

       NAME        STATE     READ WRITE CKSUM
       tank        ONLINE       0     0     0
         raidz1-0  ONLINE       0     0     0
           ada1    ONLINE       0     0     0
           ada2    ONLINE       0     0     0
           ada3    ONLINE       0     0     0
           ada4    ONLINE       0     0     0

    errors: No known data errors

1. take root snapshot: `zfs snapshot -r tank@backup`
2. zfs send snapshot to file: `zfs send -Rv tank@backup | bzip2 > tank_backup.bz2`
3. take offline one disk of the current raidz and move the snapshot (backup) there.
4. destroy raiz1-0 pool: `zpool destroy tank`
5. create a mirror pool zfs tank mirror ada1 ada2: `zpool create tank mirror ada1 ada2`
6. receive backup to mirror: `bzip2 -c -d tank_backup.bz2 | zfs receive -F tank`
7. increase size of tank zfs add tank mirror ada3 ada4: `zpool add -f tank mirror ada3 ada4`

> umount /mnt <-- before using the disk

Removing a disk:

    zpool offline tank ada4

Format disk and move backup to it:

    newfs /dev/ada4
    mount /dev/ada4 /mnt/
    mv /tank/tank_backup.bz2 /mnt/

zpool status:

     pool: tank
    state: ONLINE
     scan: none requested
    config:

        NAME        STATE     READ WRITE CKSUM
        tank        ONLINE       0     0     0
          mirror-0  ONLINE       0     0     0
            ada1    ONLINE       0     0     0
            ada2    ONLINE       0     0     0
          mirror-1  ONLINE       0     0     0
            ada3    ONLINE       0     0     0
            ada4    ONLINE       0     0     0

    errors: No known data errors


How to determine if HDD employ a 4k sector [AF](http://en.wikipedia.org/wiki/Advanced_Format)
---------------------------------------------------------------------------------------------

    smartctl -a /dev/ada1 | less

Outputs something like:

    Sector Sizes:     512 bytes logical, 4096 bytes physical

Increase capacity by replacing disks
------------------------------------

    zpool set autoexpand=on tank

Now I need to replace the 2TB disk with the 4TB disk at a time or if I have available disk use something like:

    zpool replace tank ada1 adaX


Add spare drives:

    zpool add tank spare ada8 ada9



Swap
----

To create swap on ZFS:

    zfs create -V 2G -o org.freebsd:swap=on -o checksum=off -o compression=off -o dedup=off -o sync=disabled -o primarycache=none tank/swap

Re-enable swap:

    # swapon /dev/zvol/tank/swap

To increase size:

    # swapoff /dev/zvol/tank/swap

Then destory the previous vol:

    # zfs destroy tank/swap

Create the new vol and use swapon again


Replace bad disks: https://blogs.oracle.com/mmusante/entry/howto_replace_a_bad_disk

more info: https://pthree.org/2012/12/04/zfs-administration-part-i-vdevs/

ZFS on MAC OS X
---------------

Create a mirror:

    sudo zpool create -f -o ashift=12 -O normalization=formD tank mirror /dev/disk1 /dev/disk2


rc.conf
-------

Don't forget to enable ZFS on rc.conf:

    zfs_enable="YES"
