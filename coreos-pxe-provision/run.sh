#!/bin/bash
set -e

#### Template configs from default_config combined with user config:
/data/docker_configurator
python3 /config/download_images.py
python3 /config/mount_isos.py
python3 /config/pxelinux_config.py
python3 /config/coreos_ignition.py
nginx &

echo "### Computed dnsmasq.conf:"
cat -n /etc/dnsmasq.conf
echo ""

sleep 0.5
echo "### Ignition configs:"
ls /data/ignition/*.{ign,yaml} | xargs -iXX bash -c "echo XX && cat -n XX"
grep -H "^error" /data/ignition/*.ign && echo "Looks like there's an error in the ignition file" && exit 1
echo ""

echo "### Allowed dhcp hosts:"
cat -n /etc/dhcp_hosts.txt
echo ""

#### Start the DHCP/tftp server:
dnsmasq -C /etc/dnsmasq.conf --dhcp-hostsfile /etc/dhcp_hosts.txt --no-daemon
