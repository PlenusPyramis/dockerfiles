#! /usr/bin/env bash
set -e

# Minimal debian mirror

DEBIAN_RELEASE=${DEBIAN_RELEASE:-buster}
DEBIAN_MIRROR=${DEBIAN_MIRROR:-"http://debian.csail.mit.edu/debian/"}
COMPONENTS=( main )
REPOS=( ${DEBIAN_RELEASE} ${DEBIAN_RELEASE}-updates )

# Create repository mirrors if they don't exist
set +e
for component in ${COMPONENTS[@]}; do
  for repo in ${REPOS[@]}; do
    aptly mirror list -raw | grep "^${repo}$"
    if [[ $? -ne 0 ]]; then
      echo "Creating mirror of ${repo} repository."
      aptly mirror create \
            -architectures=amd64 -filter-with-deps -filter="apparmor|apt-listchanges|apt-utils|base-passwd|bash|bash-completion|bind9-host|busybox|bzip2|console-setup|dash|debconf-i18n|debian-faq|dialog|diffutils|discover|dmidecode|doc-debian|efibootmgr|eject|findutils|firmware-linux-free|gdbm-l10n|geoip-database|grep|grub-efi-amd64|grub-efi-amd64-signed|gzip|hdparm|hostname|iamerican|ibritish|ifupdown|init|installation-report|iptables|iputils-ping|isc-dhcp-client|isc-dhcp-common|iso-codes|krb5-locales|laptop-detect|less|liblockfile-bin|libnss-systemd|libpam-systemd|libsasl2-modules|linux-image-amd64|logrotate|lsb-release|lsof|lvm2|man-db|manpages|nano|ncurses-bin|ncurses-term|netcat-traditional|os-prober|pciutils|perl|powermgmt-base|publicsuffix|python|reportbug|rsyslog|sed|shim-signed|sysvinit-utils|task-english|task-ssh-server|telnet|traceroute|tzdata|usbutils|util-linux-locales|vim-tiny|wamerican|wget|whiptail|xauth|xz-utils" ${repo} ${DEBIAN_MIRROR} ${repo} ${component}
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
