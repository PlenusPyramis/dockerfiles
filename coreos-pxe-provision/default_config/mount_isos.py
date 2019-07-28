import yaml
import os
import sys
from mako.template import Template
from mako.lookup import TemplateLookup
from mako import exceptions as mako_exceptions
import logging
from docker_configurator import load_merged_config, render_to_files, deep_merge

logging.basicConfig(level=logging.INFO)
logger=logging.getLogger("mount_isos")

template_lookup = TemplateLookup(directories=['/config/templates'])

def main():
    config = load_merged_config()
    for iso, config in config['isos'].items():
        path = config['destination']
        if not os.path.exists(path):
            logger.error("Missing ISO image: {path}".format(path=path))
            sys.exit(1)
        try:
            os.makedirs(config['mount'])
        except FileExistsError:
            pass
        logger.info("Mounting {path} to {mount}".format(path=path, mount=config['mount']))
        if os.system("mount -o loop {path} {mount}".format(path=path, mount=config['mount'])) != 0:
            logger.error("Failed to maount iso: {iso}".format(iso=iso))
            sys.exit(1)

if __name__ == "__main__":
    main()
