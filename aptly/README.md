# docker-aptly

Start aptly service:

```
docker run \
  --detach=true \
  --restart=always \
  --name="aptly" \
  --publish 80:80 \
  --volume aptly:/opt/aptly \
  --env FULL_NAME="Ryan McGuire" \
  --env EMAIL_ADDRESS="ryan@plenuspyramis.com" \
  --env GPG_PASSWORD="PickAPassword" \
  --env HOSTNAME=aptly.app.lan.rymcg.tech \
  plenuspyramis/aptly:latest
```

Configure a partial debian mirror. This is a list of the packages installed on a
minimal server:

```
docker exec -it aptly gpg --no-default-keyring --keyring trustedkeys.gpg --keyserver pool.sks-keyservers.net --recv-keys 04EE7237B7D453EC 648ACFD622F3D138 EF0F382A1A7B6500 DCC9EFBF77E11517
docker exec -it aptly aptly -architectures="amd64" mirror create -filter-with-deps -filter="apparmor|apt-listchanges|apt-utils|base-passwd|bash|bash-completion|bind9-host|busybox|bzip2|console-setup|dash|debconf-i18n|debian-faq|dialog|diffutils|discover|dmidecode|doc-debian|efibootmgr|eject|findutils|firmware-linux-free|gdbm-l10n|geoip-database|grep|grub-efi-amd64|grub-efi-amd64-signed|gzip|hdparm|hostname|iamerican|ibritish|ifupdown|init|installation-report|iptables|iputils-ping|isc-dhcp-client|isc-dhcp-common|iso-codes|krb5-locales|laptop-detect|less|liblockfile-bin|libnss-systemd|libpam-systemd|libsasl2-modules|linux-image-amd64|logrotate|lsb-release|lsof|lvm2|man-db|manpages|nano|ncurses-bin|ncurses-term|netcat-traditional|os-prober|pciutils|perl|powermgmt-base|publicsuffix|python|reportbug|rsyslog|sed|shim-signed|sysvinit-utils|task-english|task-ssh-server|telnet|traceroute|tzdata|usbutils|util-linux-locales|vim-tiny|wamerican|wget|whiptail|xauth|xz-utils" debian-main http://debian.csail.mit.edu/debian/ buster main
docker exec -it aptly aptly mirror update debian-main
```



___

* Copyright 2019 PlenusPyramis
* Copyright 2018-2019 Artem B. Smirnov
* Copyright 2016 Bryan J. Hong
* Licensed under the Apache License, Version 2.0
