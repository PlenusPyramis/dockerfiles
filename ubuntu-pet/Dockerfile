FROM ubuntu:18.04
MAINTAINER PlenusPyramis "https://github.com/PlenusPyramis/dockerfiles"

## WARNING: Do not publish this image. Always build a fresh image.
## The ssh host keys are generated on build, so each deployment requires a unique image.

## Only SSH client keys are allowed.
## The root password is randomized when the image is built, and is not known after that point.

RUN apt-get update \
    && apt-get install -y openssh-server \
    && mkdir /var/run/sshd \
    && (echo -n "root:" ; < /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-32}; echo) | chpasswd \
    && mkdir /root/.ssh \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN echo "Configuring SSH" \
    && sed -ri 's/^#?PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -ri 's/^#?PasswordAuthentication\s+.*/PasswordAuthentication no/' /etc/ssh/sshd_config \
    && sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config

EXPOSE 22
CMD    ["/usr/sbin/sshd", "-D"]
