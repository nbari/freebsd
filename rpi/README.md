# wifi

Accept the realtek licence:

    legal.realtek.license_ack=1

in  ``/etc/rc.conf``:

    wlans_urtwn0="wlan0"
    ifconfig_wlan0="ssid the.sid WPA DHCP"

cat /etc/wpa_supplicant.conf:

	network={
			ssid="the.sid"
			scan_ssid=1
			proto=WPA RSN
			pairwise=CCMP
			psk="thepassword"
			priority=5
	}
