#!/bin/bash
set -e

#### Template configs from default_config combined with user config:
python3 /config/docker_configurator.py
mkdir -p /tftp/preseed
python3 /config/preseed_templates.py

echo "### Computed dnsmasq.conf:"
cat -n /etc/dnsmasq.conf
echo ""
echo "### Allowed DHCP hosts:"
cat -n /etc/dhcp_hosts.txt
echo ""

if [[ $(cat /etc/dhcp_hosts.txt | wc -l) -eq "0" ]]; then
    echo "Warning: No DHCP hosts have been defined!"
    echo "(Will keep running anyway so that you can check the incoming DHCP request log.)"
    echo ""
fi

#### Start the DHCP/tftp server:
dnsmasq -C /etc/dnsmasq.conf --dhcp-hostsfile /etc/dhcp_hosts.txt --no-daemon
