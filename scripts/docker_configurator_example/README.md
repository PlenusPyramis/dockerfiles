```
ssh docker1 "mkdir -p /etc/containers/docker_configurator_example" && \
    scp config.yaml docker1:/etc/containers/docker_configurator_example && \
    docker build -t docker_configurator_example . && \
    docker run --rm -it \
       -v /etc/containers/docker_configurator_example/config.yaml:/config/config.yaml \
        docker_configurator_example
```
