% for n, entry in enumerate(menu_entries):
label entry${n}
        menu label ^${entry["message"]}
        kernel ${entry["kernel"]}
        append initrd=${entry["initrd"]} vga=788 --- ${entry.get("args","")}
% endfor
