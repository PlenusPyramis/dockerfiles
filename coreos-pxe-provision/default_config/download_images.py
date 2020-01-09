import yaml
import os
import sys
from mako.template import Template
from mako.lookup import TemplateLookup
from mako import exceptions as mako_exceptions
import logging
import hashlib
import requests
import shutil
from docker_configurator import load_merged_config, render_to_files, deep_merge

logging.basicConfig(level=logging.INFO)
logger=logging.getLogger("download_images")

def sha256sum(filename):
    h  = hashlib.sha256()
    b  = bytearray(128*1024)
    mv = memoryview(b)
    with open(filename, 'rb', buffering=0) as f:
        for n in iter(lambda : f.readinto(mv), 0):
            h.update(mv[:n])
    return h.hexdigest()

def download_file(url, destination):
    with requests.get(url, stream=True) as r:
        with open(destination, 'wb') as f:
            shutil.copyfileobj(r.raw, f)
    return destination

def main():
    config = load_merged_config()
    for image, details in (list(config['images'].items()) + list(config['isos'].items())):
        path = details['destination']
        if not os.path.exists(path):
            logger.info("Downloading {u} to {p} ... ".format(u=details['url'], p=path))
            try:
                os.makedirs(os.path.dirname(path))
            except FileExistsError:
                pass
            download_file(details['url'], path)
        if os.path.exists(path):
            if sha256sum(path) == details['sha256']:
                logger.info("Found existing image/iso with correct SHA256: {p}".format(p=path))
            else:
                logger.error("Invalid SHA256 for image/iso: {p}".format(p=path))
                logger.error("Manually remove the file and try again.")
                exit(1)
        else:
            logger.error("Image/iso not found: {p}".format(p=path))
            exit(1)

if __name__ == "__main__":
    main()
