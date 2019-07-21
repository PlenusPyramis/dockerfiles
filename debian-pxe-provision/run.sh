#!/bin/bash
set -e

echo ""

check_vars() {
    ## Check that required environment variables are set
    ## Pass names of env vars as arguments
    ALL_SET=1
    for i; do
        if [ ! -v $i ]; then
           ALL_SET=0
           echo "$i is unset."
        fi
    done
    if [ $ALL_SET -ne 1 ]; then
        echo "Aborting."
        exit 1
    fi
}

## Required environment variables:
check_vars INTERFACE

## Regenerate the dhcp_hosts.txt file
if [ ! -f $DHCP_HOSTS ]; then
    echo "You need to supply a data volume for: $DHCP_HOSTS"
    exit 1
fi
TMP_HOSTS=$(mktemp)
cat ${DHCP_HOSTS:-/data/dhcp_hosts.txt} | grep -v "^\W*$" | grep -v '^\W*#' > $TMP_HOSTS
while read host_config; do
    # Convert MAC addresses to dnsmasq desired format:
    mac=$(echo "$host_config"  | cut -d "," -f 1 | tr "-" ":")
    rest=$(echo "$host_config" | sed 's/[^,]*//')
    echo $mac$rest
done < $TMP_HOSTS > /etc/dhcp_hosts.txt
DHCP_HOSTS=/etc/dhcp_hosts.txt

## Non-required environment variables that use defaults:
PUBLIC_IP=${PUBLIC_IP:-$(ip addr show dev $INTERFACE | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/')}
SUBNET=$(echo "$PUBLIC_IP" | cut -d '.' -f 1,2,3).0
CLIENT_INTERFACE=${CLIENT_INTERFACE:-eno1}
GATEWAY=$(/sbin/ip route | awk '/default/ { print $3 }')
DHCP_BOOT=${DHCP_BOOT:-debian-installer/amd64/bootnetx64.efi}
DEBIAN_MIRROR=${DEBIAN_MIRROR:-http://debian.csail.mit.edu/debian/}
DEBIAN_DOMAIN=$(echo $DEBIAN_MIRROR | awk -F[/:] '{print $4}')

#### Main dnsmasq config file generated from environment variables:
cat <<EOF > /etc/dnsmasq.conf
## The host interface name to bind to:
interface=$INTERFACE
bind-interfaces

no-resolv
server=1.0.0.1
server=1.1.1.1
strict-order

## Override DNS for DEBIAN_MIRROR:
address=/$DEBIAN_DOMAIN/$PUBLIC_IP

## Only serve static leases to specific MAC addresses:
dhcp-range=$SUBNET,static
## Boot UEFI:
dhcp-boot=$DHCP_BOOT,pxeserver,$PUBLIC_IP
## Specify gateway
dhcp-option=3,$GATEWAY
## Specify DNS servers
dhcp-option=6,$PUBLIC_IP

# Legacy BIOS (non-UEFI) should boot pxelinux instead:
pxe-service=X86PC, "Boot BIOS PXE", pxelinux.0

dhcp-no-override
log-dhcp

pxe-prompt="Booting PXE Client in 5 seconds...", 5

enable-tftp
tftp-root=/tftp/

no-daemon

EOF

#### Output the config to the start of the docker log:

echo "### Computed dnsmasq.conf:"
cat -n /etc/dnsmasq.conf
echo ""
echo "### Allowed DHCP hosts:"
cat -n $DHCP_HOSTS
echo ""

#### GRUB UEFI config:
cat <<EOF > /tftp/debian-installer/amd64/grub/grub.cfg
if loadfont \$prefix/font.pf2 ; then
  set gfxmode=800x600
  insmod efi_gop
  insmod efi_uga
  insmod video_bochs
  insmod video_cirrus
  insmod gfxterm
  insmod png
  terminal_output gfxterm
fi

set menu_color_normal=cyan/blue
set menu_color_highlight=white/blue

menuentry 'Automated Install in 5..4..3..2..1.. ' {
    set background_color=black
    linux    /debian-installer/amd64/linux vga=788 --- auto=true interface=$CLIENT_INTERFACE netcfg/dhcp_timeout=60 netcfg/choose_interface=$CLIENT_INTERFACE priority=critical preseed/url=tftp://$PUBLIC_IP/preseed/\${net_default_mac}.cfg DEBCONF_DEBUG=5 quiet
    initrd   /debian-installer/amd64/initrd.gz
}
set default="0"
set timeout=5
EOF

#### PXELINUX BIOS (non-UEFI) default config:
cat <<EOF > /tftp/pxelinux.cfg/default
## The default config does nothing because no MAC was matched.
path debian-installer/amd64/boot-screens/
default debian-installer/amd64/boot-screens/vesamenu.c32
label default
    menu label ^Ooops, this machine has no preseed configuration.
EOF

####
#### Check for preseed configurations
mkdir /tftp/preseed
MISSING_PRESEEDS=0
for mac in $(cat $DHCP_HOSTS | cut -d ',' -f 1); do
    mac=$(echo "$mac" | tr ':' '-')
    mac_with_colons=$(echo "$mac" | tr '-' ':')
    PRESEED=/data/preseed/$mac.cfg
    if [ ! -f $PRESEED ]; then
        MISSING_PRESEEDS=$((MISSING_PRESEEDS+1))
        echo "Missing preseed file: $PRESEED"
    else
        cp $PRESEED /tftp/preseed/$mac.cfg
        cp $PRESEED /tftp/preseed/$mac_with_colons.cfg
        cat <<EOF > /tftp/pxelinux.cfg/01-$mac
path debian-installer/amd64/boot-screens/
default debian-installer/amd64/boot-screens/vesamenu.c32
include debian-installer/amd64/boot-screens/$mac.cfg
EOF

        cat <<EOF > /tftp/debian-installer/amd64/boot-screens/$mac.cfg
label autoinstall
        menu label ^Automated Install in 5..4..3..2..1..
        kernel debian-installer/amd64/linux
        append vga=788 initrd=debian-installer/amd64/initrd.gz --- auto=true interface=$CLIENT_INTERFACE netcfg/dhcp_timeout=60 netcfg/choose_interface=$CLIENT_INTERFACE priority=critical preseed/url=tftp://$PUBLIC_IP/preseed/$mac.cfg DEBCONF_DEBUG=5 quiet
default autoinstall
timeout 5
EOF

    fi
done
if [ $MISSING_PRESEEDS -gt 0 ]; then
    echo "Create missing preseed files, or comment the host in $DHCP_HOSTS"
    exit 1
fi



#### Start the DHCP/tftp server:
dnsmasq -C /etc/dnsmasq.conf --dhcp-hostsfile $DHCP_HOSTS --no-daemon
