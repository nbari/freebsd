Core dump analysis
==================


Recompile binary with debugging symbols included, on FreeBSD put this on  /etc/make.conf and recompile port:

    WITH_DEBUG=yes

check ``kern.coredump=1``

    sysctl kern.coredump

debug using

    gdb /path/to/the/binary /path/to/the/foo.core

next use:

    bt


http://www.freebsd.org/doc/en/books/developers-handbook/debugging.html
