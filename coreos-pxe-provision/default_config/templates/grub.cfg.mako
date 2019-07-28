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
% for entry in menu_entries:
menuentry '${entry["message"]}' {
    set background_color=black
    linux    ${entry["kernel"]} vga=788 --- ${entry.get("args","")}
    initrd   ${entry["initrd"]}
}
% endfor
% if auto_install['enabled']:
set default="${auto_install['entry']}"
set timeout=${auto_install['timeout']}
% endif