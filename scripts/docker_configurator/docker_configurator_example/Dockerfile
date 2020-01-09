FROM alpine:latest

RUN apk --no-cache add python3 py3-mako py3-yaml bash
# Import docker_configurator from a central URL to avoid unecessary copies everywhere:
ADD https://raw.githubusercontent.com/PlenusPyramis/dockerfiles/master/scripts/docker_configurator.py /config/docker_configurator.py

# Add container specific run script:
ADD run.sh /usr/local/bin/run.sh
# Import the container default config:
ADD default_config /config

# Run docker_configurator before running the container script:
CMD /usr/bin/python3 /config/docker_configurator.py && /bin/bash /usr/local/bin/run.sh

