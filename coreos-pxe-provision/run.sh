#!/bin/bash
set -e

#### Template configs from default_config combined with user config:
python3 /config/docker_configurator.py
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

#### Start the DHCP/tftp server:
dnsmasq -C /etc/dnsmasq.conf --dhcp-hostsfile /etc/dhcp_hosts.txt --no-daemon
