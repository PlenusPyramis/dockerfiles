FROM alpine:latest
LABEL MAINTAINER="ryan@enigmacurry.com"

ARG ARCH=amd64
ARG DEBIAN_DIST=buster
ARG DEBIAN_MIRROR=http://ftp.us.debian.org

RUN mkdir /tftp
WORKDIR /tftp
RUN wget -O - ${DEBIAN_MIRROR}/debian/dists/${DEBIAN_DIST}/main/installer-${ARCH}/current/images/netboot/netboot.tar.gz | tar xvz

SHELL ["/bin/ash", "-o", "pipefail", "-c"]
RUN apk --no-cache add dnsmasq bash && \
    mkdir -p /etc/default/ && \
    echo -e "ENABLED=1\nIGNORE_RESOLVCONF=yes" > /etc/default/dnsmasq

ADD run.sh /usr/local/bin/run.sh

CMD ["/usr/local/bin/run.sh"]
