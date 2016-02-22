Find parent
-----------

When trying to kill zombies, use this to find it's parents:

    ps -auxd | grep -B 15 -A 5 <PID>

or

    ps -auxd >~/parent.txt


Kill/drop all TCP connection, just keep ssh (22):

    tcpdrop -l -a | grep -vw 22 | sh
