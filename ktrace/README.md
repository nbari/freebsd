ktrace -- enable kernel process tracing
=======================================

To stop tracing:

    $ ktrace -C

To trace a pid:

    $ ktrace -p 1234

kdump -- display kernel trace data
==================================

    $ kdump -f my-ktrace.out | less
