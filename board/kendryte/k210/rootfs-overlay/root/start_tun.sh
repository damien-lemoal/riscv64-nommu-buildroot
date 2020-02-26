#!/bin/sh

if [ -z "$1" ]
  then echo "Usage: $0 SSID PASSWORD HOST_TUNNEL"
  exit 1
fi

/root/esptun tun0 /dev/ttyS1 $1 $2 $3 23232
/sbin/ip link set dev tun0 mtu 1472
/sbin/ip addr add 10.0.1.2/24 dev tun0
/sbin/ip link set tun0 up
/sbin/ip route add default via 10.0.1.1 dev tun0

ip addr show dev tun0
ip route show
