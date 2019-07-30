#!/usr/bin/env python
# -*- encoding: utf-8 -*-
from __future__ import absolute_import
from __future__ import print_function

import io
import re
from glob import glob
import os
from os.path import basename
from os.path import dirname
from os.path import join
from os.path import splitext
import subprocess
import shutil
import shlex

import distutils.cmd
from setuptools import find_packages
from setuptools import setup
import setuptools.command.build_py
from zipfile import ZipFile
import platform
import logging

logging.basicConfig(level=logging.INFO)
log = logging.getLogger("setup")

program_name = "docker_configurator"

def read(*names, **kwargs):
    return io.open(
        join(dirname(__file__), *names),
        encoding=kwargs.get('encoding', 'utf8')
    ).read()


def requirements():
    with open('requirements.txt') as f:
        return [line.strip() for line in f if line.strip()]

def get_version():
    if shutil.which('git'):
        current_tag = subprocess.Popen(
            shlex.split("git tag --points-at HEAD"),
            stdout=subprocess.PIPE).communicate()[0].decode('utf-8').strip()
        if len(current_tag) > 0:
            return current_tag
    return "SNAPSHOT"

class PyinstallerCommand(distutils.cmd.Command):
    """A custom command to run pyinstaller"""

    description = 'run pyinstaller to create all-in-one executable'
    user_options = [
        # The format is (long option, short option, description).
    ]

    def initialize_options(self):
        pass

    def finalize_options(self):
        pass

    def run(self):
        """Run command."""
        command = ['pyinstaller', "docker_configurator.py",
                   "--clean", "-F", "-n", program_name]
        log.info(
            'Running command: %s' % str(command))
        subprocess.check_call(command)

        version = get_version()
        operating_system = platform.system()
        pkgname = '{program_name}-{version}-{platform}'.format(
            program_name=program_name, version=version, platform=operating_system)
        zip_path = os.path.join(
                'dist', '{pkgname}.zip'.format(pkgname=pkgname))
        with ZipFile(zip_path, 'w') as zip:
            if operating_system == "Windows":
                exe = '{name}.exe'.format(name=program_name)
            else:
                exe = '{name}'.format(name=program_name)
            zip.write(os.path.join('dist', exe), "{dirname}/{exe}".format(dirname=pkgname, exe=exe))
            zip.write("README.md", "{dirname}/README.md".format(dirname=pkgname))

            log.info("Built package for {platform} : {f}".format(platform=operating_system, f=zip_path))

class BuildPyCommand(setuptools.command.build_py.build_py):
    """Custom build command."""
    def run(self):
        setuptools.command.build_py.build_py.run(self)

setup(
    name=program_name,
    version=get_version(),
    cmdclass={
        'build': PyinstallerCommand,
        'build_py': BuildPyCommand
    },
    license='MIT',
    description='Single YAML file configuration and templating tool for docker containers',
    author='EnigmaCurry',
    url='https://github.com/PlenusPyramis/dockerfiles/tree/master/scripts/docker_configurator',
    packages=find_packages('src'),
    package_dir={'': 'src'},
    py_modules=[splitext(basename(path))[0] for path in glob('src/*.py')],
    include_package_data=True,
    zip_safe=False,
    classifiers=[
        # complete classifier list: http://pypi.python.org/pypi?%3Aaction=list_classifiers
        'Development Status :: 5 - Production/Stable',
        'Intended Audience :: Developers',
        'License :: OSI Approved :: MIT License',
        'Operating System :: Unix',
        'Operating System :: POSIX',
        'Operating System :: Microsoft :: Windows',
        'Programming Language :: Python',
        'Programming Language :: Python :: 3.7',
        'Programming Language :: Python :: Implementation :: CPython',
        'Topic :: Utilities',
    ],
    install_requires=requirements(),
    entry_points={
        'console_scripts': [
            'docker_configurator = docker_configurator:main',
        ]
    },
)
