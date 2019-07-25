## The host interface name to bind to:
interface=${interface}
bind-interfaces

## These are the upstream DNS servers:
no-resolv
% for ip in dns:
server=${ip}
% endfor
strict-order

% if debian_mirror.get('lazy_mirror', False):
## Override DNS for the upstream debian mirror with a local caching proxy:
address=/${debian_mirror['hostname']}/${lazy_mirror_ip}
% endif

## Only serve static leases to specific MAC addresses:
dhcp-range=${dhcp['range_start']},${dhcp['range_end']},${dhcp['netmask']},${dhcp['lease_time']}
## Specify gateway for client
dhcp-option=3,${dhcp['gateway']}
## Specify DNS server for client
dhcp-option=6,${public_ip}
## iPXE http://forum.ipxe.org/showthread.php?tid=6077
dhcp-match=set:ipxe,175 # iPXE sends a 175 option.
dhcp-boot=tag:!ipxe,${dhcp['uefi_boot']},pxeserver,${public_ip}
dhcp-boot=http://${public_ip}:${http_port}/pxelinux.0

# Legacy BIOS (non-UEFI) should boot pxelinux instead:
pxe-service=X86PC, "Boot BIOS PXE", ${dhcp['bios_boot']}

## "simple and safe" dhcp option:
dhcp-no-override
## Verbose dhcp logging:
log-dhcp

pxe-prompt="Booting PXE Client in 5 seconds...", 5

## TFTP
enable-tftp
tftp-root=/data/

## No daemon because we're using docker:
no-daemon
