label autoinstall
        menu label ^Automated Install in 5..4..3..2..1..
        kernel debian-installer/amd64/linux
        append vga=788 initrd=debian-installer/amd64/initrd.gz --- auto=true hostname=unassigned-hostname domain=${dhcp['domain']} interface=auto hw-detect/load_firmware=false netcfg/dhcp_timeout=60 priority=${installer_priority} preseed/url=tftp://${public_ip}/preseed/${mac}.cfg DEBCONF_DEBUG=5 quiet
default autoinstall
timeout 5
