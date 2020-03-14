FROM ubuntu:18.04
MAINTAINER PlenusPyramis "https://github.com/PlenusPyramis/dockerfiles"

RUN apt-get update \
    && apt-get install -y openssh-server locales-all mosh \
    && mkdir /var/run/sshd \
    && mkdir /root/.ssh \
    && chmod 700 /root/.ssh \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY sshd_entrypoint.sh /usr/bin/sshd_entrypoint
COPY sshd_config /etc/ssh/sshd_config

RUN rm /etc/ssh/ssh_host_* \
    && chmod a+x /usr/bin/sshd_entrypoint

EXPOSE 22
EXPOSE 60000-61000/udp
ENTRYPOINT ["/usr/bin/sshd_entrypoint"]
