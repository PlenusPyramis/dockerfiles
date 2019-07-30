import yaml
import os
import sys
from mako.template import Template
from mako.lookup import TemplateLookup
from mako import exceptions as mako_exceptions
import logging
from docker_configurator import load_merged_config, render_to_files, deep_merge

logging.basicConfig(level=logging.INFO)
logger=logging.getLogger('coreos_ignition')

IGNITION_SRC = '/data/ignition/'

template_lookup = TemplateLookup(directories=['/config/templates'])
ignition_template = template_lookup.get_template('coreos_ignition.yaml.mako')

def main():
    config = load_merged_config()

    try:
        os.makedirs(IGNITION_SRC)
    except FileExistsError:
        pass
    os.chdir(IGNITION_SRC)

    for mac, client_config in config['clients'].items():
        yaml_path = '{mac}.yaml'.format(mac=mac)
        client_merged_config = deep_merge(config['client_defaults'], client_config)
        client_merged_config['mac'] = mac

        ## Render the systemd unit files:
        units = []
        for name, unit_config in client_config.get('units', []).items():
            if unit_config == None:
                unit_config = {}
            unit = {'name': name, **unit_config}
            if unit.get('enabled', False):
                unit['enabled'] = "true"
                unit_template = template_lookup.get_template('units/{name}.mako'.format(name=name))
                unit['contents'] = unit_template.render(**unit_config).replace("\n","\\n").replace("\"","\\\"")
            else:
                unit['enabled'] = "false"
                unit['contents'] = "## Masked"
            units.append(unit)
        client_merged_config['units'] = units

        ## Render the ignition template:
        render_to_files(ignition_template, yaml_path,
                        ssh_keys=config['ssh_keys'], dns=config['dns'],
                        dhcp=config['dhcp'], **client_merged_config)
        os.system("cat -n {yaml_path}".format(yaml_path=yaml_path))
        ign_dest = os.path.join(IGNITION_SRC,'{mac}.ign'.format(mac=mac))
        cmd='fcct --strict --pretty --input {yaml_path} > {ign_dest} ; echo'.format(
            yaml_path=yaml_path, ign_dest=ign_dest)
        logger.info(cmd)
        os.system(cmd)
        if not os.path.exists(ign_dest):
            logger.error('fcct failed to transform to ignition file: {ign_dest}'.format(
                yaml_path=yaml_path, ign_dest=ign_dest))
            sys.exit(1)
        logger.info('Created ignition file: {ign_dest}'.format(
            ign_dest=os.path.join(IGNITION_SRC,ign_dest)))
        if os.path.getsize(ign_dest) == 0:
            logger.error('Ignition file is empty : {ign_dest}'.format(
                ign_dest=os.path.join(IGNITION_SRC,ign_dest)))
            sys.exit(1)

if __name__ == '__main__':
    main()
