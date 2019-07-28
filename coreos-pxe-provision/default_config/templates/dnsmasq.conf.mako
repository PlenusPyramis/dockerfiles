## The host interface name to bind to:
interface=${interface}
bind-interfaces

## These are the upstream DNS servers:
no-resolv
% for ip in dns:
server=${ip}
% endfor
strict-order

## Only serve static leases to specific MAC addresses:
dhcp-range=${dhcp['range_start']},${dhcp['range_end']},${dhcp['netmask']},${dhcp['lease_time']}
## Specify gateway for client
dhcp-option=3,${dhcp['gateway']}
## Specify DNS server for client
dhcp-option=6,${dns[0]},${dns[1]}
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

## TFTP
enable-tftp
tftp-root=/data/

## No daemon because we're using docker:
no-daemon
