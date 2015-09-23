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

When a system needs to send large chunks of data out over a computer network,
the chunks first need breaking down into smaller segments that can pass through
all the network elements like routers and switches between the source and
destination computers. This process is referred to as segmentation. Often the
TCP protocol in the host computer performs this segmentation. Offloading this
work to the NIC is called TCP segmentation offload (TSO).

For example, a unit of 64kB (65,536 bytes) of data is usually segmented to 46
segments of 1448 bytes each before it is sent through the NIC and over the
network. With some intelligence in the NIC, the host CPU can hand over the 64
KB of data to the NIC in a single transmit-request, the NIC can break that
data down into smaller segments of 1448 bytes, add the TCP, IP, and data link
layer protocol headers - according to a template provided by the host's TCP/IP
stack - to each segment, and send the resulting frames over the network. This
significantly reduces the work done by the CPU. As of 2014 many new NICs on the
market support TSO.

Some network cards implement TSO generically enough that it can be used for
offloading fragmentation of other transport layer protocols, or by doing IP
fragmentation for protocols that don't support fragmentation by themselves, such
as UDP.

https://en.wikipedia.org/wiki/Large_segment_offload

http://cloudnull.io/2012/07/xenserver-network-tuning/
