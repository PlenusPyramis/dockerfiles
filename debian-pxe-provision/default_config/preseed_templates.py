import yaml
from mako.template import Template
from mako.lookup import TemplateLookup
from mako import exceptions as mako_exceptions
import logging
from docker_configurator import load_merged_config, render_to_files, deep_merge

logging.basicConfig(level=logging.INFO)
logger=logging.getLogger(__name__)


template_lookup = TemplateLookup(directories=['/config/templates'])
preseed_template = template_lookup.get_template("preseed.cfg.mako")
pxelinux_template = template_lookup.get_template("pxelinux.cfg.mako")
bootscreen_template = template_lookup.get_template("boot_screen.cfg.mako")
postinstall_template = template_lookup.get_template("post_install.sh.mako")

def main():
    config = load_merged_config()
    for mac, client_config in config['clients'].items():
        preseed_path = "/tftp/preseed/{mac}.cfg".format(mac=mac)
        preseed_alt_path = "/tftp/preseed/{mac}.cfg".format(mac=mac.replace("-",":"))
        pxelinux_path = "/tftp/pxelinux.cfg/01-{mac}".format(mac=mac)
        bootscreen_path = "/tftp/debian-installer/amd64/boot-screens/{mac}.cfg".format(mac=mac)
        postinstall_path = "/tftp/preseed/{mac}_postinstall.sh".format(mac=mac)

        client_merged_config = deep_merge(config['client_defaults'], client_config)

        render_to_files(preseed_template, [preseed_path, preseed_alt_path],
                        mac=mac,
                        dhcp=config['dhcp'],
                        debian_mirror=config['debian_mirror'],
                        public_ip=config['public_ip'], **client_merged_config)
        render_to_files(pxelinux_template, pxelinux_path, mac=mac)
        render_to_files(bootscreen_template, bootscreen_path,
                        dhcp=config['dhcp'],
                        public_ip=config['public_ip'],
                        installer_priority=config['installer_priority'],
                        mac=mac)
        render_to_files(postinstall_template, postinstall_path,
                        dns=config['dns'], **client_merged_config)

if __name__ == "__main__":
    main()
