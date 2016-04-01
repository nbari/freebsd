Using multiple fib's  on t2.large 36 IP's 33 per network:

```text
ifconfig_xn0="SYNCDHCP -tso fib 0"
ifconfig_xn0_aliases="inet 10.0.8.6-16/32"
ifconfig_xn1="SYNCDHCP -tso fib 1"
ifconfig_xn1_aliases="inet 10.0.8.18-28/32"
ifconfig_xn2="SYNCDHCP -tso fib 2"
ifconfig_xn2_aliases="inet 10.0.8.30-40/32"
```text


Using fixed IP's:

```text
ifconfig_xn0="SYNCDHCP -tso fib 0"
ifconfig_xn0_aliases="inet 10.0.8.6-16/32"
ifconfig_xn1="inet 10.0.8.17 netmask 255.255.248.0 -tso fib 1"
ifconfig_xn1_aliases="inet 10.0.8.18-28/32"
ifconfig_xn2="inet 10.0.8.29 netmask 255.255.248.0 -tso fib 2"
ifconfig_xn2_aliases="inet 10.0.8.30-40/32"
```text
