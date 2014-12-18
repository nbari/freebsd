VLAN ID 100
-----------

Vlan inside jail with vnet:

    ifconfig vlan create

    ifconfig vlan0 vlan 100 vlandev epair3b

    ifconfig vlan0 dhcp



Bridge on host:

    ifconfig vlan0 create
    ifconfig vlan0 vlan 100 vlandev em0
    ifconfig bridge1 addm vlan0
    ifconfig bridge1 ifmaxaddr vlan0 10


Full example with vlan, vnet, 2 nic:

    #-----------------------------------------------------------------------
    # net
    #-----------------------------------------------------------------------
    ifconfig_em1="inet 192.168.1.2 netmask 255.255.255.0"
    ifconfig_em1_alias0="inet 192.168.1.30 netmask 255.255.255.0"
    ifconfig_em1_alias1="inet 192.168.1.31 netmask 255.255.255.0"
    ifconfig_em1_alias2="inet 192.168.1.32 netmask 255.255.255.0"
    ifconfig_em1_alias3="inet 192.168.1.33 netmask 255.255.255.0"
    ifconfig_em1_alias4="inet 192.168.1.34 netmask 255.255.255.0"
    ifconfig_em1_alias5="inet 192.168.1.35 netmask 255.255.255.0"
    ifconfig_em1_alias6="inet 192.168.1.36 netmask 255.255.255.0"
    ifconfig_em1_alias7="inet 192.168.1.37 netmask 255.255.255.0"
    ifconfig_em1_alias8="inet 192.168.1.38 netmask 255.255.255.0"
    ifconfig_em1_alias9="inet 192.168.1.39 netmask 255.255.255.0"
    ifconfig_em1_alias10="inet 192.168.1.70 netmask 255.255.255.0"
    ifconfig_em0="up"
    vlans_em0="100"
    cloned_interfaces="bridge0 bridge1 epair0 epair1 epair2 epair3 epair4 tap0 tap1"
    autobridge_interfaces="bridge0 bridge1"
    autobridge_bridge0="em1 epair0a epair1a epair2a tap0 tap1 epair4a"
    autobridge_bridge1="em0.100 epair3a"
    ifconfig_bridge0="up"
    ifconfig_bridge1="up"
    ifconfig_epair0a="up"
    ifconfig_epair1a="up"
    ifconfig_epair2a="up"
    ifconfig_epair3a="up"
    ifconfig_epair4a="up"
    ifconfig_tap0="up"
    ifconfig_em0_100="up"
