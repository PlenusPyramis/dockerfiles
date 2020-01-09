# acme-dehydrated

This is a fork of
[matrix-org/docker-dehydrated](https://github.com/matrix-org/docker-dehydrated) -
this is an entirely new abbreviated README for DigitalOcean DNS.

Maintain all of your Let's Encrypt certficates, and take care of renewals, with
one docker container that takes about 2MB of ram. This uses the DNS-01 ACME
challenge type, to enable the use of private sub-domains and private ip ranges.
No public DNS names need to be created, nor any external port needs to be
opened, like it would be for traditional HTTP challenge. The only other
requirment is that you have your domain registrar point to a DNS service
supported by one of the [lexicon
providers](https://github.com/AnalogJ/lexicon/#providers). (This tutorial
assumes you are using DigitalOcean for your domain's DNS provider, but you can
easily change it if its supported by lexicon.)

## Setup

Create a directory on the docker host server:

```
mkdir -p /etc/containers/acme-dehydrated
```

Create the docker-compose file in
`/etc/containers/acme-dehydrated/production.yaml`:

```
version: '2'
services:
  dehydrated:
    image: docker.io/plenuspyramis/acme-dehydrated
    restart: unless-stopped
    volumes:
      - ./data:/data
    environment:
      - DEHYDRATED_GENERATE_CONFIG=yes
      - DEHYDRATED_CA=https://acme-v02.api.letsencrypt.org/directory
      - DEHYDRATED_CHALLENGE=dns-01
      - DEHYDRATED_KEYSIZE=4096
      - DEHYDRATED_HOOK=/usr/local/bin/lexicon-hook
      - DEHYDRATED_RENEW_DAYS=30
      - DEHYDRATED_KEY_RENEW=yes
      - DEHYDRATED_EMAIL=username@example.com
      - DEHYDRATED_ACCEPT_TERMS=yes
      - PROVIDER=digitalocean
      - LEXICON_DIGITALOCEAN_TOKEN=abcdefghijklmnopqrstuvwxyz0123456789
```

Change the following:

 * `DEHYDRATED_EMAIL` - your email address. It must be valid for Lets Encrypt to
   work, and you will receive notifications for expired certificates here.
 * `PROVIDER` - if you are using some other DNS provider, put the [lexicon
   provider
   name](https://github.com/AnalogJ/lexicon/tree/master/lexicon/providers) here
   (minus the `.py`).
 * `LEXICON_DIGITALOCEAN_TOKEN` - Generate a new [DigitalOcean API
   token](https://cloud.digitalocean.com/account/api/tokens) and put it here. If
   you use a different DNS provider, erase this variable and put the appropriate
   providers token instead with the name like [`LEXICON_{DNS Provider Name}_{Auth
   Type}`](https://github.com/AnalogJ/lexicon#environmental-variables)
 * `DEHYDRATED_CA` - The above is set for **production** use. However, it is
   recommended to use **staging** when you are first testing this. So change
   `DEHYDRATED_CA` to `https://acme-staging-v02.api.letsencrypt.org/directory`.
   **IMPORTANT**: You cannot change this value later without also cleaning up the
   data directory first. (remove everything but domains.txt)
   
Create the `data` directory:

```
mkdir -p /etc/containers/acme-dehydrated/data
```

Create `/etc/containers/acme-dehydrated/data/domains.txt` to contain all of the
domains (and sub-domains) to register with Let's Encrypt. Create :

```
## domains.txt
## One line per certificate, each line lists all of the (sub-)domains valid for the certificate.

example.com www.example.com
other-example.com www.other-example.com subdomain2.other-example.com subdomain3.other-example.com
```

Create the container:

```
docker-compose -f /etc/containers/acme-deyhdrated/production.yml up -d
```

View the logs to debug:

```
docker logs acmedeyhdrated_dehydrated_1
```

Certificates for each domain are generated in
`/etc/containers/acme-dehydrated/data/certs`

## Usage on proxmox

Automatically update the proxmox TLS certificates with `acme-dehydrated`:

 * Create a VM to run docker
 * name: `sys-docker`
 * ram: 1GB
 * cores: 1
 * Start it up, install docker, setup SSH for root proxmox user ssh pubkey
    * [Ubuntu docker install guide](https://docs.docker.com/install/linux/docker-ce/ubuntu/)
    * From the proxmox host as root: `ssh-copy-id root@sys-docker`
 * Setup `acme-dehydrate` as above, adding the full proxmox domain to
   `data/domains.txt` (Check `hostname -f` on the proxmox server).
 * Find the ip address of the VM (run: `ip addr`) and add it to the proxmox host
   `/etc/hosts`. (`1.2.3.4  sys-docker.example.com sys-docker`)

On the proxmox host, create a daily cron job to copy the new certificates.
Create `/etc/cron.daily/install-proxmox-ssl-certificates`:

```
#!/bin/sh
#
# cron daily: Install fresh ssl certs from acme-dehydrated on sys-docker:

set -e

## Set DOCKER_HOST to the name of the docker server running acme-dehydrated
## The proxmox root ssh public key (/root/.ssh/id_rsa.pub) must be allowed on the DOCKER_HOST (/root/.ssh/authorized_keys)
DOCKER_HOST=sys-docker
DOMAIN=$(hostname -f)

scp ${DOCKER_HOST}:/etc/containers/acme-deyhdrated/data/certs/${DOMAIN}/fullchain.pem /etc/pve/local/pveproxy-ssl.pem
scp ${DOCKER_HOST}:/etc/containers/acme-deyhdrated/data/certs/${DOMAIN}/privkey.pem /etc/pve/local/pveproxy-ssl.key
systemctl restart pveproxy
```

Set the right permissions:

```
chmod 755 /etc/cron.daily/install-proxmox-ssl-certificates
```
