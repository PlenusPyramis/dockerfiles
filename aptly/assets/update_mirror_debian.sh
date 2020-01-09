#! /usr/bin/env bash
set -e

# Minimal debian mirror

DEBIAN_RELEASE=${DEBIAN_RELEASE:-buster}
DEBIAN_MIRROR=${DEBIAN_MIRROR:-"http://debian.csail.mit.edu/debian/"}
COMPONENTS=( main )
REPOS=( ${DEBIAN_RELEASE} ${DEBIAN_RELEASE}-updates )

BASE_FILTER=${BASE_FILTER:-"adduser|apparmor|apt|apt-listchanges|apt-utils|base-files|base-passwd|bash|bash-completion|bind9-host|bsdmainutils|bsdutils|busybox|bzip2|ca-certificates|console-setup|console-setup-linux|coreutils|cpio|cron|dash|dbus|debconf|debconf-i18n|debconf-utils|debian-archive-keyring|debian-faq|debianutils|deborphan|dialog|dictionaries-common|diffutils|discover|discover-data|distro-info-data|dmeventd|dmidecode|dmsetup|doc-debian|e2fsprogs|efibootmgr|eject|emacsen-common|fdisk|file|findutils|firmware-linux-free|gcc-8-base|gdbm-l10n|geoip-database|gettext-base|gpgv|grep|groff-base|grub-common|grub-efi-amd64|grub-efi-amd64-bin|grub-efi-amd64-signed|grub2-common|gzip|hdparm|hostname|iamerican|ibritish|ienglish-common|ifupdown|init|init-system-helpers|initramfs-tools|initramfs-tools-core|installation-report|iproute2|iptables|iputils-ping|isc-dhcp-client|isc-dhcp-common|iso-codes|ispell|kbd|keyboard-configuration|klibc-utils|kmod|krb5-locales|laptop-detect|less|libacl1|libaio1|libapparmor1|libapt-inst2.0|libapt-pkg5.0|libargon2-1|libattr1|libaudit-common|libaudit1|libbind9-161|libblkid1|libbsd0|libbz2-1.0|libc-bin|libc-l10n|libc6|libcap-ng0|libcap2|libcap2-bin|libcom-err2|libcryptsetup12|libcurl3-gnutls|libdb5.3|libdbus-1-3|libdebconfclient0|libdevmapper-event1.02.1|libdevmapper1.02.1|libdiscover2|libdns-export1104|libdns1104|libedit2|libefiboot1|libefivar1|libelf1|libestr0|libexpat1|libext2fs2|libfastjson4|libfdisk1|libffi6|libfreetype6|libfstrm0|libfuse2|libgcc1|libgcrypt20|libgdbm-compat4|libgdbm6|libgeoip1|libgmp10|libgnutls30|libgpg-error0|libgssapi-krb5-2|libhogweed4|libicu63|libidn11|libidn2-0|libip4tc0|libip6tc0|libiptc0|libisc-export1100|libisc1100|libisccc161|libisccfg163|libjson-c3|libk5crypto3|libkeyutils1|libklibc|libkmod2|libkrb5-3|libkrb5support0|libldap-2.4-2|libldap-common|liblmdb0|liblocale-gettext-perl|liblockfile-bin|liblognorm5|liblvm2cmd2.03|liblwres161|liblz4-1|liblzma5|libmagic-mgc|libmagic1|libmnl0|libmount1|libmpdec2|libncurses6|libncursesw6|libnetfilter-conntrack3|libnettle6|libnewt0.52|libnfnetlink0|libnftnl11|libnghttp2-14|libnss-systemd|libp11-kit0|libpam-modules|libpam-modules-bin|libpam-runtime|libpam-systemd|libpam0g|libpci3|libpcre2-8-0|libpcre3|libperl5.28|libpipeline1|libpng16-16|libpopt0|libprocps7|libprotobuf-c1|libpsl5|libpython-stdlib|libpython2-stdlib|libpython2.7-minimal|libpython2.7-stdlib|libpython3-stdlib|libpython3.7-minimal|libpython3.7-stdlib|libreadline5|libreadline7|librtmp1|libsasl2-2|libsasl2-modules|libsasl2-modules-db|libseccomp2|libselinux1|libsemanage-common|libsemanage1|libsepol1|libslang2|libsmartcols1|libsqlite3-0|libss2|libssh2-1|libssl1.1|libstdc++6|libsystemd0|libtasn1-6|libtext-charwidth-perl|libtext-iconv-perl|libtext-wrapi18n-perl|libtinfo6|libuchardet0|libudev1|libunistring2|libusb-0.1-4|libusb-1.0-0|libuuid1|libwrap0|libx11-6|libx11-data|libxau6|libxcb1|libxdmcp6|libxext6|libxml2|libxmuu1|libxtables12|libzstd1|linux-base|linux-image-4.19.0-5-amd64|linux-image-amd64|locales|login|logrotate|lsb-base|lsb-release|lsof|lvm2|man-db|manpages|mawk|mime-support|mokutil|mount|nano|ncurses-base|ncurses-bin|ncurses-term|netbase|netcat-traditional|openssh-client|openssh-server|openssh-sftp-server|openssl|os-prober|passwd|pciutils|perl|perl-base|perl-modules-5.28|popularity-contest|powermgmt-base|procps|publicsuffix|python|python-apt-common|python-minimal|python2|python2-minimal|python2.7|python2.7-minimal|python3|python3-apt|python3-certifi|python3-chardet|python3-debconf|python3-debian|python3-debianbts|python3-httplib2|python3-idna|python3-minimal|python3-pkg-resources|python3-pycurl|python3-pysimplesoap|python3-reportbug|python3-requests|python3-six|python3-urllib3|python3.7|python3.7-minimal|readline-common|reportbug|rsyslog|sed|sensible-utils|shim-helpers-amd64-signed|shim-signed|shim-signed-common|shim-unsigned|systemd|systemd-sysv|sysvinit-utils|tar|task-english|task-ssh-server|tasksel|tasksel-data|telnet|traceroute|tzdata|ucf|udev|usb.ids|usbutils|util-linux|util-linux-locales|vim-common|vim-tiny|wamerican|wget|whiptail|xauth|xkb-data|xxd|xz-utils|zlib1g"}

if [ -v FILTER ]; then
    FILTER="$BASE_FILTER|$FILTER"
else
    FILTER=$BASE_FILTER
fi

# Create repository mirrors if they don't exist
set +e
for component in ${COMPONENTS[@]}; do
  for repo in ${REPOS[@]}; do
    aptly mirror list -raw | grep "^${repo}$"
    if [[ $? -ne 0 ]]; then
      echo "Creating mirror of ${repo} repository."
      aptly mirror create \
            -architectures=amd64 -filter-with-deps -filter="$FILTER" ${repo} ${DEBIAN_MIRROR} ${repo} ${component}
    fi
  done
done
set -e

# Update all repository mirrors
for component in ${COMPONENTS[@]}; do
  for repo in ${REPOS[@]}; do
    echo "Updating ${repo} repository mirror.."
    aptly mirror update ${repo}
  done
done

# Create snapshots of updated repositories
for component in ${COMPONENTS[@]}; do
  for repo in ${REPOS[@]}; do
    echo "Creating snapshot of ${repo} repository mirror.."
    SNAPSHOTARRAY+="${repo}-`date +%Y%m%d%H` "
    aptly snapshot create ${repo}-`date +%Y%m%d%H` from mirror ${repo}
  done
done

echo ${SNAPSHOTARRAY[@]}

# Merge snapshots into a single snapshot with updates applied
echo "Merging snapshots into one.." 
aptly snapshot merge -latest                 \
  ${DEBIAN_RELEASE}-merged-`date +%Y%m%d%H`  \
  ${SNAPSHOTARRAY[@]}

# Publish the latest merged snapshot
set +e
aptly publish list -raw | awk '{print $2}' | grep "^${DEBIAN_RELEASE}$"
if [[ $? -eq 0 ]]; then
  aptly publish switch            \
    -passphrase="${GPG_PASSWORD}" \
    ${DEBIAN_RELEASE} ${DEBIAN_RELEASE}-merged-`date +%Y%m%d%H`
else
  aptly publish snapshot \
    -passphrase="${GPG_PASSWORD}" \
    -distribution=${DEBIAN_RELEASE} ${DEBIAN_RELEASE}-merged-`date +%Y%m%d%H`
fi
set -e

# Export the GPG Public key
if [[ ! -f /opt/aptly/public/aptly_repo_signing.key ]]; then
  gpg --export --armor > /opt/aptly/public/aptly_repo_signing.key
fi

# Generate Aptly Graph
aptly graph -output /opt/aptly/public/aptly_graph.png
