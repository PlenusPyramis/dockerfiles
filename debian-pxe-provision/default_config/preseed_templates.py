import yaml
from mako.template import Template
from mako.lookup import TemplateLookup
from mako import exceptions as mako_exceptions
import logging

logging.basicConfig(level=logging.INFO)
logger=logging.getLogger(__name__)

with open("/config/config.yaml") as f:
    config = yaml.safe_load(f)

template_lookup = TemplateLookup(directories=['/config/templates'])
preseed_template = template_lookup.get_template("preseed.cfg.mako")
pxelinux_template = template_lookup.get_template("pxelinux.cfg.mako")
bootscreen_template = template_lookup.get_template("boot_screen.cfg.mako")

for mac, host_config in config['clients'].items():
    host_config = {**config, **host_config}
    preseed_path = "/tftp/preseed/{mac}.cfg".format(mac=mac)
    preseed_alt_path = "/tftp/preseed/{mac}.cfg".format(mac=mac.replace("-",":"))
    logging.info("Writing preseed configs: {} {}".format(preseed_path, preseed_alt_path))
    try:
        preseed = preseed_template.render(**host_config)
    except:
        print(mako_exceptions.text_error_template().render())
        raise

    with open(preseed_path, 'w') as f:
        f.write(preseed)

    with open(preseed_alt_path, 'w') as f:
        f.write(preseed)

    pxelinux_path = "/tftp/pxelinux.cfg/01-{mac}".format(mac=mac)
    logging.info("Writing pxelinux config: {}".format(pxelinux_path))
    try:
        pxelinux = pxelinux_template.render(mac=mac)
    except:
        print(mako_exceptions.text_error_template().render())
        raise
    with open(pxelinux_path, 'w') as f:
        f.write(pxelinux)

    bootscreen_path = "/tftp/debian-installer/amd64/boot-screens/{mac}.cfg".format(mac=mac)
    logging.info("Writing bootscreen config: {}".format(bootscreen_path))
    try:
        bootscreen = bootscreen_template.render(public_ip=config['public_ip'], mac=mac)
    except:
        print(mako_exceptions.text_error_template().render())
        raise
    with open(bootscreen_path, 'w') as f:
        f.write(bootscreen)
