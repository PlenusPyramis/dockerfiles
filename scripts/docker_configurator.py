"""
Docker Configurator
http://www.github.com/EnigmaCurry/docker-configurator


This tool creates self-configuring docker containers given a single
YAML file.

Run this script before your main docker CMD. It will write fresh
config files on every startup of the container, based off of Mako
templates embedded in the docker image, as well as values specified in
a YAML file provided in a mounted volume.

The idea of this is that container configuration is kind of hard
because everyone does it differently. This creates a standard way of
doing it for containers that I write. A single file to configure
everything.

---------------------------------------------------------------------------

Copyright (c) 2015 Ryan McGuire

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
"""

import yaml
from mako.template import Template
from mako.lookup import TemplateLookup
from mako import exceptions as mako_exceptions
import logging
import argparse
import os
import shutil

logging.basicConfig(level=logging.INFO)
logger=logging.getLogger("docker_configurator")

class DockerConfigurator(object):
    """Reads a yaml config file and creates application config files from
    Mako templates"""
    def __init__(self, config_path="/config"):
        # Load the default config:
        default_config = os.path.join(config_path,"default.yaml")
        self.config = self._load_config(default_config)
        logger.info("Default configuration loaded from {}".format(default_config))
        # Merge with the user config, if available:
        user_config = os.path.join(config_path,"config.yaml")
        if os.path.exists(user_config):
            self.config.update(self._load_config(user_config))
            logger.info("User configuration loaded from {}".format(user_config))
        else:
            logger.warning("User configuration was not found. Copying default config to {}".format(user_config))
            shutil.copyfile(default_config, user_config)
        # Setup templates
        self.template_lookup = TemplateLookup(directories=[os.path.join(config_path, "templates")])

    def _load_config(self, yaml_config_path):
        with open(yaml_config_path) as f:
            data = yaml.safe_load(f)
        if data is None:
            raise AssertionError('YAML config is empty')
        return data

    def configure(self, template_map=None):
        """Create config files from templates

        template_map is a dictionary of template files to config file locations to create
        """
        if template_map is None:
            try:
                template_map = self.config['template_map']
            except KeyError:
                logger.error("Missing template_map from config.yaml")
                raise
        for template_name, config_path in template_map.items():
            template = self.template_lookup.get_template(template_name)
            directory = os.path.dirname(config_path)
            if not os.path.exists(directory):
                logger.info("Creating directory: {}".format(directory))
                os.makedirs(directory)
            logger.info("Rendering template {} to {}".format(template_name, config_path))
            if os.path.exists(config_path):
                logger.warning("Overwriting existing config file: {}".format(config_path))
            with open(config_path, 'w') as f:
                try:
                    f.write(template.render(**self.config))
                except:
                    print(mako_exceptions.text_error_template().render())
                    raise

def main():
    parser = argparse.ArgumentParser(description='Docker Configurator',
                                     formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument("-c", "--config-path", help="Path to config and templates directory", default="/config")
    args = parser.parse_args()

    dc = DockerConfigurator(args.config_path)
    dc.configure()

if __name__ == "__main__":
    main()
