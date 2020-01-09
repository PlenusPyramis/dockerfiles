FROM alpine:latest
LABEL MAINTAINER="ryan@enigmacurry.com"

ARG ARCH=amd64
ARG DEBIAN_DIST=buster
ARG DEBIAN_MIRROR=http://ftp.us.debian.org
ARG FCCT_VERSION=v0.1.0

RUN mkdir /data
WORKDIR /data
RUN wget -O - ${DEBIAN_MIRROR}/debian/dists/${DEBIAN_DIST}/main/installer-${ARCH}/current/images/netboot/netboot.tar.gz | tar xvz && \
    wget -O /usr/local/bin/fcct https://github.com/coreos/fcct/releases/download/${FCCT_VERSION}/fcct-x86_64-unknown-linux-gnu && \
    chmod a+x /usr/local/bin/fcct
RUN apk --no-cache add python3 py3-mako py3-yaml dnsmasq bash nginx && \
    mkdir /run/nginx && \
    mkdir -p /etc/default/ && \
    echo -e "ENABLED=1\nIGNORE_RESOLVCONF=yes" > /etc/default/dnsmasq

ADD run.sh /usr/local/bin/run.sh
ADD default_config /config
ADD https://raw.githubusercontent.com/PlenusPyramis/dockerfiles/master/scripts/docker_configurator.py /config/docker_configurator.py

CMD ["/usr/local/bin/run.sh"]
