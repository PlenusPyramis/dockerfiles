% for n, entry in enumerate(menu_entries):
label entry${n}
        menu label ^${entry["message"]}
        kernel ${entry["kernel"]}
        append initrd=${entry["initrd"]} --- ip=dhcp rd.neednet=1 coreos.inst=yes ${display_args} coreos.inst.install_dev=${install_dev} coreos.inst.image_url=http://${public_ip}:8000/images/${entry['image']} coreos.inst.ignition_url=http://${public_ip}:8000/ignition/${mac}.ign ${entry.get("args","")}
% endfor
% if auto_install['enabled']:
default ${auto_install['entry']}
timeout ${auto_install['timeout']}
% endif
