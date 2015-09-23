Large segment offload
=====================

In computer networking, large segment offload (LSO) is a technique for
increasing outbound throughput of high-bandwidth network connections by
reducing CPU overhead. It works by queuing up large buffers and letting the
network interface card (NIC) split them into separate packets. The technique
is also called TCP segmentation offload (TSO) when applied to TCP, or generic
segmentation offload (GSO).

To disable tso:

    ifconfig xn0 -tso

via /etc/rc.conf:

    ifconfig_DEFAULT="SYNCDHCP -tso"
