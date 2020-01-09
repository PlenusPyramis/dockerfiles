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

IGNITION_SRC = "/data/ignition/"

def main():
    config = load_merged_config()
    os.chdir(IGNITION_SRC)
    for ign_src in [x for x in os.listdir(IGNITION_SRC) if x.endswith(".yaml")]:
        ign_dest = "{name}.ign".format(name=ign_src.split(".")[0])
        cmd="fcct --strict --pretty --input {ign_src} > {ign_dest}".format(ign_src=ign_src, ign_dest=ign_dest)
        logger.info(cmd)
        os.system(cmd)
        if not os.path.exists(ign_dest):
            logger.error("fcct failed to transform to ignition file: {ign_dest}".format(ign_src=ign_src, ign_dest=ign_dest))
            sys.exit(1)
        logger.info("Created ignition file: {ign_dest}".format(ign_dest=ign_dest))
if __name__ == "__main__":
    main()
