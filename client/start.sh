#!/bin/bash

echo "My AWS openvpn server ip is: $SERVER_IP"
echo "Client certs file to be used is: $CLIENT_NAME"

sed -i.bak s/SERVER_IP/$SERVER_IP/ /etc/openvpn/openvpn.conf
sed -i.bak s/CLIENT_NAME/$CLIENT_NAME/ /etc/openvpn/openvpn.conf

# start openvpn service
conf_file="/etc/openvpn/openvpn.conf"
sysctl -w net.ipv4.ip_forward=1
iptables -F
/sbin/iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
/sbin/iptables -A FORWARD -i eth0 -o tun0 -m state --state RELATED,ESTABLISHED -j ACCEPT
/sbin/iptables -A FORWARD -i tun0 -o eth0 -j ACCEPT
/usr/sbin/openvpn --config $conf_file
