#!/bin/bash
# Pin a NetworkManager connection to a static IPv4 address.
# Usage: set-static-ip.sh <connection> <ip/cidr> <gateway> <dns>
#   e.g. set-static-ip.sh "WiFi" 192.168.1.50/24 192.168.1.1 192.168.1.1
set -e
CON="${1:?connection name}"; ADDR="${2:?ip/cidr}"; GW="${3:?gateway}"; DNS="${4:-$3}"
nmcli con mod "$CON" ipv4.method manual ipv4.addresses "$ADDR" \
	ipv4.gateway "$GW" ipv4.dns "$DNS" connection.autoconnect yes
echo "set $CON -> $ADDR gw $GW dns $DNS (takes effect on next activation/reboot)"
