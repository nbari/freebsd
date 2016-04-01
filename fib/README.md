FIB - Forwarding Information Base

Using multiple fib's  on t2.large 36 IP's 33 per network:

    ifconfig_xn0="SYNCDHCP -tso fib 0"
    ifconfig_xn0_aliases="inet 10.0.8.6-16/32"
    ifconfig_xn1="SYNCDHCP -tso fib 1"
    ifconfig_xn1_aliases="inet 10.0.8.18-28/32"
    ifconfig_xn2="SYNCDHCP -tso fib 2"
    ifconfig_xn2_aliases="inet 10.0.8.30-40/32"

Using fixed IP's:

    ifconfig_xn0="SYNCDHCP -tso fib 0"
    ifconfig_xn0_aliases="inet 10.0.8.6-16/32"
    ifconfig_xn1="inet 10.0.8.17 netmask 255.255.248.0 -tso fib 1"
    ifconfig_xn1_aliases="inet 10.0.8.18-28/32"
    ifconfig_xn2="inet 10.0.8.29 netmask 255.255.248.0 -tso fib 2"
    ifconfig_xn2_aliases="inet 10.0.8.30-40/32"


Need to check if removing fibs works when using fixed IP's


To get the number of routetables:

    sysctl net.fibs

/etc/sysctl.conf:

    net.add_addr_allfibs=0

This enables to add routes to all FIBs for new interfaces by default. When this
is set to 0, it will only allocate routes on interface changes for the FIB of
the caller when adding a new set of addresses to an interface. Note that this
tunable is set to 1 by default.
