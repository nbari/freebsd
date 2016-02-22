Find parent
-----------

When trying to kill zombies, use this to find it's parents:

    ps -auxd | grep -B 15 -A 5 <PID>

or

    ps -auxd >~/parent.txt
