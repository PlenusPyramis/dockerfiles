import yaml
import os
import sys
from mako.template import Template
from mako.lookup import TemplateLookup
from mako import exceptions as mako_exceptions
import logging
from docker_configurator import load_merged_config, render_to_files, deep_merge

logging.basicConfig(level=logging.INFO)
logger=logging.getLogger(__name__)


template_lookup = TemplateLookup(directories=['/config/templates'])

def main():
    config = load_merged_config()
    for iso, config in config['isos'].items():
        iso = "/data/isos/{iso}".format(iso=iso)
        if not os.path.exists(iso):
            logger.error("Missing ISO image: {iso}".format(iso=iso))
            sys.exit(1)
        os.makedirs(config['mount'])
        logger.info("Mounting {iso} to {mount}".format(iso=iso, mount=config['mount']))
        os.system("mount -o loop {iso} {mount}".format(iso=iso, mount=config['mount']))

if __name__ == "__main__":
    main()
