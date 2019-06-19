# dnsmasq

DNS / DHCP / TFTP server

Includes PXE boot for debian-stretch netboot.

Use docker `--network host` in order to bind to DNS and DHCP ports. 

Must use docker `--priviliged` if using TFTP.

