Add 2GB swap:

    dd if=/dev/zero of=/swap bs=1m count=2048

chmod:

     chmod 0600 /swap

add to ``/etc/fstab``:

    md99    none    swap    sw,file=/swap,late  0   0
