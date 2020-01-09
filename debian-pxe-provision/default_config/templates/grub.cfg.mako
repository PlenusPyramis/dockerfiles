if loadfont $prefix/font.pf2 ; then
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
    linux    /debian-installer/amd64/linux vga=788 --- auto=true hostname=unassigned-hostname domain=${dhcp['domain']} netcfg/dhcp_timeout=60 hw-detect/load_firmware=false interface=auto priority=${installer_priority} preseed/url=tftp://${public_ip}/preseed/${"${net_default_mac}"}.cfg DEBCONF_DEBUG=5 quiet
    initrd   /debian-installer/amd64/initrd.gz
}
set default="0"
set timeout=5
