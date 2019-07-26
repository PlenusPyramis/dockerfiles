#!/bin/bash
set -e

#### Template configs from default_config combined with user config:
python3 /config/docker_configurator.py
python3 /config/mount_isos.py
python3 /config/coreos_ignition.py
nginx &

echo "### Computed dnsmasq.conf:"
cat -n /etc/dnsmasq.conf
echo ""

echo "### /data/ignition/default_ignition.yaml "
cat /data/ignition/default_ignition.yaml
echo ""

echo "### /data/ignition/default_ignition.ign "
cat /data/ignition/default_ignition.ign
echo ""

if [ $(cat /data/ignition/default_ignition.ign | wc -l) -eq 0 ]; then
    echo "Ignition file is empty. Check for the fcct error above. Your config is probably bad."
    exit 1
fi


#### Start the DHCP/tftp server:
dnsmasq -C /etc/dnsmasq.conf --dhcp-hostsfile /etc/dhcp_hosts.txt --no-daemon
