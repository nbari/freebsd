Portknocking
=============

Only open port 22 after X number of attemps to connect on port 1234:

```sh
# Table for allowed IPs - gets auto populated via portknocking
table <portknock_ssh> persist

block drop # block policy
# Allow everyone to hit 'any' on port '1234' - pf proxies tcp connection
#  [if not using 'synproxy', the connection is never established to
#    'overload' the rule]
#  5 attempts in 15 seconds
pass in log quick proto tcp from any to any port {1234} synproxy state \
  (max-src-conn-rate 5/15, overload <portknock_ssh>)

#Allow IPs that have been 'overload'ed into the portknock_ssh table
pass in log quick proto tcp from {<portknock_ssh>} to any port {ssh}

```

Then put a crontab on a per needed basis to expire all IPs in that table
that have not been referenced in 60 seconds (or use expiretable):

```sh
*  *  *  *  * /sbin/pfctl -vt portknock_ssh -T expire 60
```
