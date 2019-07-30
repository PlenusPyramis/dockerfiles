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

See the included example project:  `docker_configurator_example`

---------------------------------------------------------------------------

Copyright (c) 2019 PlenusPyramis
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
import collections

logging.basicConfig(level=logging.INFO)
logger=logging.getLogger("docker_configurator")

__version__ = "v0.9.0"

def deep_merge(*dicts):
    """
    Non-destructive deep-merge of multiple dictionary-like objects

    >>> a = { 'first' : { 'all_rows' : { 'pass' : 'dog', 'number' : '1', 'recipe':['one','two'] } } }
    >>> b = { 'first' : { 'all_rows' : { 'fail' : 'cat', 'number' : '5', 'recipe':['three'] } } }
    >>> c = deep_merge(a, b)
    >>> a == { 'first' : { 'all_rows' : { 'pass' : 'dog', 'number' : '1', 'recipe':['one','two'] } } }
    True
    >>> b == { 'first' : { 'all_rows' : { 'fail' : 'cat', 'number' : '5', 'recipe':['three'] } } }
    True
    >>> c == { 'first' : { 'all_rows' : { 'pass' : 'dog', 'fail' : 'cat', 'number' : '5', 'recipe':['three'] } } }
    True
    >>> c == deep_merge(a, b, c)
    True
    """
    # Wrap the merge function so that it is no longer destructive of its destination:
    def merge(source, destination):
        # Thanks @_v1nc3nt_ https://stackoverflow.com/a/20666342/56560
        if isinstance(destination, collections.abc.Mapping):
            for key, value in source.items():
                if isinstance(value, dict):
                    node = destination.setdefault(key, {})
                    merge(value, node)
                else:
                    destination[key] = value
    final = {}
    for d in dicts:
        merge(d, final)
    return final

def load_merged_config(config_path="/config"):
    default_config_path = os.path.join(config_path,"default.yaml")
    user_config_path = os.path.join(config_path, "config.yaml")

    with open(default_config_path) as f:
        default_config = yaml.safe_load(f)
        if default_config is None:
            raise AssertionError('Default config is empty: {}'.format(default_config_path))
        logger.info("Default configuration loaded from {}".format(default_config_path))

    if os.path.exists(user_config_path):
        with open(user_config_path) as f:
            user_config = yaml.safe_load(f)
            logger.info("User configuration loaded from {}".format(user_config_path))
    else:
        user_config = {}
        logger.warning("User configuration was not found. Using default config only.")
    return deep_merge(default_config, user_config)

def render_to_files(template, output, **params):
    def write(path, data):
        if os.path.exists(path):
            logger.warning("Overwriting existing file: {}".format(path))
        with open(path, 'w') as f:
            f.write(data)
    try:
        logging.info("Rendering template: {} to file(s): {}".format(template.uri, output))
        data = template.render(**params)
        if type(output) == str:
            write(output, data)
        else:
            for out in output:
                write(out, data)
        return data
    except:
        print(mako_exceptions.text_error_template().render())
        raise

class DockerConfigurator(object):
    """Reads a yaml config file and creates application config files from Mako templates

    The config file should have a key called 'template_map' which is a map of
    templates to final system paths.

    # Example yaml for config.yaml or default.yaml:
    template_map:
     - my_config.mako: /etc/my_config
     - my_script.sh.mako: /usr/local/bin/cool_script
    """
    def __init__(self, config_path="/config"):
        self.config = load_merged_config(config_path)
        self.template_lookup = TemplateLookup(directories=[os.path.join(config_path, "templates")])

    def write_configs(self, template_map=None):
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

            render_to_files(template, config_path, **self.config)

def main():
    parser = argparse.ArgumentParser(description='Docker Configurator',
                                     formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument("-c", "--config-path", help="Path to config and templates directory", default="/config")
    args = parser.parse_args()

    dc = DockerConfigurator(args.config_path)
    dc.write_configs()

if __name__ == "__main__":
    main()
