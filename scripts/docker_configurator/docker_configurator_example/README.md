# docker_configurator_example

This is an example project that utilizes
[docker_configurator.py](../docker_configurator.py) a simple way of configuring
docker containers with a single YAML file.

 * User configuration is in [config.yaml](config.yaml)
 * Default configuration is in [default_config/default.yaml](default_config/default.yaml)
 * The User configuration [deep
   merges](https://github.com/PlenusPyramis/dockerfiles/blob/835da61aa34e8edcfa6d43ec83254f3de5ac0a05/scripts/docker_configurator.py#L58-L87)
   on top of the Default configuration.
 * The User configuration lives outside the container, mounted at runtime with
   `-v`.
 * The Default configuration is baked into the container image.
 * Configuration file templates live in
   [default_config/templates](default_config/templates) and are also baked into
   the container image.
 * The Dockerfile `CMD` runs docker_configurator.py before `run.sh`, which
   templates out all of the necessary config files, taking into account the
   merged default+user config.

Running the docker_configurator_example on a remote docker-machine ([see the
parent docs for initial setup of docker-machine](../../README.md)):

```
ssh docker1 "mkdir -p /etc/containers/docker_configurator_example" && \
    scp config.yaml docker1:/etc/containers/docker_configurator_example && \
    docker build -t docker_configurator_example . && \
    docker run --rm -it \
       -v /etc/containers/docker_configurator_example/config.yaml:/config/config.yaml \
        docker_configurator_example
```
