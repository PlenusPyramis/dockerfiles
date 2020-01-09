import yaml
from mako.template import Template
from mako.lookup import TemplateLookup
from mako import exceptions as mako_exceptions
import logging
from docker_configurator import load_merged_config, render_to_files, deep_merge

logging.basicConfig(level=logging.INFO)
logger=logging.getLogger(__name__)


template_lookup = TemplateLookup(directories=['/config/templates'])
pxelinux_template = template_lookup.get_template("pxelinux.cfg.mako")
bootscreen_template = template_lookup.get_template("boot_screen.cfg.mako")

def main():
    config = load_merged_config()
    for mac, client_config in config['clients'].items():
        pxelinux_path = "/data/pxelinux.cfg/01-{mac}".format(mac=mac)
        bootscreen_path = "/data/debian-installer/amd64/boot-screens/{mac}.cfg".format(mac=mac)

        client_merged_config = deep_merge(config['client_defaults'], client_config)
        if client_merged_config.get("vga", False) == True:
            display_args = "vga=788"
        else:
            display_args = "vga=none console=tty0 console=ttyS0"
        render_to_files(pxelinux_template, pxelinux_path, mac=mac)
        render_to_files(bootscreen_template, bootscreen_path,
                        dhcp=config['dhcp'], public_ip=config['public_ip'],
                        mac=mac, menu_entries=config['menu_entries'],
                        auto_install=config['auto_install'],
                        display_args=display_args,
                        **client_merged_config)

if __name__ == "__main__":
    main()
