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

#### Start the DHCP/tftp server:
dnsmasq -C /etc/dnsmasq.conf --dhcp-hostsfile /etc/dhcp_hosts.txt --no-daemon
