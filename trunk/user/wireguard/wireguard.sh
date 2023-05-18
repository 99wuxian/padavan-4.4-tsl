#!/bin/sh

CONFIG_FILE=/etc/storage/wireguard/wg0.conf

start_wg() {
	localip="$(nvram get wireguard_localip)"
	privatekey="$(nvram get wireguard_localkey)"
	peerkey="$(nvram get wireguard_peerkey)"
	peerip="$(nvram get wireguard_peerip)"
	logger -t "WIREGUARD" "正在启动wireguard"
	ifconfig wg0 down
	ip link del dev wg0
	if [ -f "$CONFIG_FILE" ]; then
	sed -i -E "s/^[ \t]*Address[ \t]*=.*$/Address = $localip/ig" $CONFIG_FILE
	sed -i -E "s/^[ \t]*PrivateKey[ \t]*=.*$/PrivateKey = $privatekey/ig" $CONFIG_FILE
	sed -i -E "s/^[ \t]*PublicKey[ \t]*=.*$/PublicKey = $peerkey/ig" $CONFIG_FILE
	sed -i -E "s/^[ \t]*Endpoint*[ \t]*=.*$/Endpoint = $peerip/ig" $CONFIG_FILE
	wg-quick up $CONFIG_FILE
	else
	ip link add dev wg0 type wireguard
	ip link set dev wg0 mtu 1420
	ip addr add $localip dev wg0
	echo "$privatekey" > /tmp/privatekey
	wg set wg0 private-key /tmp/privatekey
	wg set wg0 peer $peerkey persistent-keepalive 25 allowed-ips 0.0.0.0/0,::/0 endpoint $peerip
	iptables -t nat -A POSTROUTING -o wg0 -j MASQUERADE
	ifconfig wg0 up
	rm /tmp/privatekey
	fi
}


stop_wg() {
	if [ -f "$CONFIG_FILE" ]; then
	wg-quick down $CONFIG_FILE
	else
	iptables -t nat -D POSTROUTING -o wg0 -j MASQUERADE
	ifconfig wg0 down
	ip link del dev wg0
	fi
	logger -t "WIREGUARD" "正在关闭wireguard"
	}



case $1 in
start)
	start_wg
	;;
stop)
	stop_wg
	;;
*)
	echo "check"
	#exit 0
	;;
esac
