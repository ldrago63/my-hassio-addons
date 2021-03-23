#!/bin/bash

# SIGTERM-handler this funciton will be executed when the container receives the SIGTERM signal (when stopping)
term_handler(){
	echo "Stopping..."
	ifdown wlan0
	ip link set wlan0 down
	ip addr flush dev wlan0
	exit 0
}

# Setup signal handlers
trap 'term_handler' SIGTERM

echo "Starting..."

echo "Set nmcli managed no"
nmcli dev set wlan0 managed no

CONFIG_PATH=/data/options.json

SSID=$(jq --raw-output ".ssid" $CONFIG_PATH)
WPA_PASSPHRASE=$(jq --raw-output ".wpa_passphrase" $CONFIG_PATH)
CHANNEL=$(jq --raw-output ".channel" $CONFIG_PATH)
ADDRESS=$(jq --raw-output ".address" $CONFIG_PATH)
NETWORK=$(jq --raw-output ".network" $CONFIG_PATH)
NETMASK=$(jq --raw-output ".netmask" $CONFIG_PATH)
BROADCAST=$(jq --raw-output ".broadcast" $CONFIG_PATH)
FIXED_IPS=$(jq --raw-output ".fixed_ips" $CONFIG_PATH)

# Enforces required env variables
required_vars=(SSID WPA_PASSPHRASE CHANNEL ADDRESS NETMASK BROADCAST)
for required_var in "${required_vars[@]}"; do
    if [[ -z ${!required_var} ]]; then
        error=1
        echo >&2 "Error: $required_var env variable not set."
    fi
done

if [[ -n $error ]]; then
    exit 1
fi

# Setup hostapd.conf
echo "Setup hostapd ..."
echo "ssid=$SSID"$'\n' >> /hostapd.conf
echo "wpa_passphrase=$WPA_PASSPHRASE"$'\n' >> /hostapd.conf
echo "channel=$CHANNEL"$'\n' >> /hostapd.conf

# Setup interface
echo "Setup interface ..."

#ip link set wlan0 down
#ip addr flush dev wlan0
#ip addr add ${IP_ADDRESS}/24 dev wlan0
#ip link set wlan0 up

echo "address $ADDRESS"$'\n' >> /etc/network/interfaces
echo "netmask $NETMASK"$'\n' >> /etc/network/interfaces
echo "broadcast $BROADCAST"$'\n' >> /etc/network/interfaces


# Setup interface
echo "Setup dhcp ..."

DHCPD_FIXED_IPS_FORMAT="$(echo 'group {\n') $(for row in $(echo "${FIXED_IPS}" | jq -r '.[] | @base64'); do
    _jq() {
     echo ${row} | base64 -d | jq -r ${1}
    }

   echo "host $(_jq '.name')           { hardware ethernet $(_jq '.mac_address'); fixed-address $(_jq '.ip');}\n"
done) $(echo '}')"

cat > /etc/dhcp/dhcpd.conf <<ENDFILE
option domain-name-servers $ADDRESS;

default-lease-time 600;
max-lease-time 7200;

authoritative;

log-facility local7;

subnet $NETWORK netmask $NETMASK {
     #option domain-name "wifi.localhost";
     option routers $ADDRESS;
     option subnet-mask $NETMASK;
     option broadcast-address $BROADCAST;
     option domain-name-servers $ADDRESS;
     range dynamic-bootp $(echo $NETWORK | cut -d . -f 1-3).2 $(echo $NETWORK |  cut -d . -f 1-3).100;
     $(echo -e $DHCPD_FIXED_IPS_FORMAT)
}
ENDFILE

ifdown wlan0
ifup wlan0

echo "Starting dhcpd daemon ..."
touch /var/lib/dhcp/dhcpd.leases
dhcpd -d -f -pf /var/run/dhcp-server/dhcpd.pid -cf /etc/dhcp/dhcpd.conf wlan0 &

echo "Starting HostAP daemon ..."
hostapd -d /hostapd.conf & wait ${!}