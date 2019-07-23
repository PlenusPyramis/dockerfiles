# debian-pxe-provision

Unattended bare metal provisioner via PXE boot and Debian netboot preseed. This
will boot systems, over the network, with either UEFI or legacy BIOS, and
automatically install debian on them.

This runs `dnsmasq` as a DHCP and tftp boot server. It binds to a real host
interface connected to the same LAN as your client machines. It only serves DHCP
to the clients that you explicitly list in `config.yaml`.

There is optional support for hosting a
[lazy-distro-mirror](https://github.com/EnigmaCurry/lazy-distro-mirrors) so that
you can cache the portions of the debian mirror you are downloading, for
speeding up subsequent installs. You can also set your own full mirror location
if you already have one.

This container is intended to be short-lived, and only running when you actually
want to be doing installations. Treat this a bit like a loaded gun, with a few
safety mechanisms.

![diagram](debian-pxe-provision-diagram.jpg)

## Config

Your only configuration is a single YAML file: [config.yaml](config.yaml)

You mount this config file into the container at runtime. This config file is
merged with another config file called
[default.yaml](default_config/default.yaml), which is already baked into the
image. The settings you put in your `config.yaml` will always take precedence
over the default config.

### Configuration variables explained

See the included example [config.yaml](config.yaml)

 * `interface` - The docker server that will run this container is going to be a
   DNS, DHCP, and TFTP server. These services need to bind to the physical
   network adapter of the server in order for other machines on the network to
   use it. This is the name of the network interface on the server (try running
   on the server: `ip addr` to look for the interface name, it's most likely
   `eth0` or `eno1`, but it is also very often different.)
 * `debian_mirror` - Pick a fast mirror geographically close to you from [the
   offical debian mirror list](https://www.debian.org/mirror/list). The URL is
   broken into parts, so for example if you chose
   `http://debian.csail.mit.edu/debian` as your mirror, you would set hostname:
   `debian.csail.mit.edu`, path: `/debian`, port: `80`. The `lazy_mirror` option
   will point clients to a local caching proxy server for the mirror (see below
   for details.)
 * `clients` - This is a list of your clients to PXE boot and install debian.
   Clients must have their phyiscal MAC address listed here and set `enabled:
   true`. All other clients that don't meet this criteria will be ignored by the
   DHCP server.

#### Client config parameters

NOTE: The preseed files are served via TFTP unencrypted, and unauthenticated.
**This means that you should not put any secrets here**. Passwords should be
immediately changed after first boot (either manually, or by some secondary
process that you implement like ansible.)

The following table shows all of the valid config options for each client:

| variable      | default         | description                                                                                                                    |
| --------      | -------         | -----------                                                                                                                    |
| enabled       | false           | Only clients explicitly set `true` will be offered DHCP.                                                                       |
| hostname      |                 | The DHCP hostname to offer                                                                                                     |
| ip_address    |                 | The DHCP IP address to offer                                                                                                   |
| root_storage  |                 | The root storage device (eg. `/dev/sda`)                                                                                       |
| root_password | password        | The initial root password. **DO NOT set a secure password here. Change it after first boot.**                                  |
| time_zone     | US/Eastern      | Time zone name (See [Wikipedia timezones](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones))                       |
| locale        | en_US           | Locale                                                                                                                         |
| xkb_keymap    | us              | Keyboard map                                                                                                                   |
| clock_utc     | true            | Whether clock is set to UTC                                                                                                    |
| user_fullname | Debian User     | The fullname for the installer created user account                                                                            |
| user_name     | debian          | The username for the installer created user account                                                                            |
| user_password | password        | The initial password for the installer created user account **DO NOT set a secure password here. Change it after first boot.** |
| dns           | 1.0.0.1,1.1.1.1 | List of DNS ip addresses to use (specify as comma-seperated string.)                                                           |

## Running

The container must be run privileged and attached to the host network.
(`--privileged --network host`)

```
docker run --rm -it \
    --privileged \
    --network host \
    -v config.yaml:/config/config.yaml \
    plenuspyramis/debian-pxe-provision
```

## Lazy mirror

If you are provisioning more than a handful of machines, you will want to host
your own local debian mirror. You can create a full mirror with a tool like
[aptly](https://www.aptly.info/) - the main debian archive mirror is around
64GB. Alternatively, you can run a
[lazy-distro-mirror](https://github.com/EnigmaCurry/lazy-distro-mirrors) which
is a caching proxy server for only the bits you actually need.

(Actually, aptly can do partial mirrors too, but if you don't know the exact
packages that the installer will need, it won't work. I know, I've tried several
times. By contrast, the Lazy Mirror Just Works.)

Here's the idea:

 * You set `debian_mirror` normally. Choose a fast mirror from [the offical
   debian mirror list](https://www.debian.org/mirror/list). **Your nodes will
   always use this URL, both during install, and after install.**
 * The trick is that `debian-pxe-provision` is a DNS server that tells PXE
   booted clients to use a different IP address for the `debian_mirror`. It
   overrides the DNS for whatever domain your chosen `debian_mirror` has, such
   that **during install `debian_mirror` will actually resolve to the the lazy
   mirror IP address**. This will save you bandwidth as your nodes will retrieve
   packages from the local lazy mirror, but they will still think they are
   getting it from the real mirror because they are using the same URL always.
 * Once the nodes reboot, they will be using their regular staticly assigned DNS
   servers, with no spoofed entries. So from then on, those nodes will use the
   real `debian_mirror` IP address. The nice thing is that the URL didn't have
   to change, so no reconfiguration is necessary post-install.
 * This way the lazy mirror doesn't need to stay running indefinitely, it only
   needs to run when you are doing installs.
 * Some people ask ["Why doesn't apt use
   SSL?"](https://whydoesaptnotusehttps.com/) - Well one reason is that things
   like this wouldn't be possible otherwise. 
   
You run the lazy mirror as an additional docker container alongside
`debian-pxe-provision`. Configure the container on the same docker server, or
the one you specify by configuring`lazy_mirror_ip`. The server must not be
running anything else on port 80 (yet).

Create the config file:

```
mkdir -p /etc/containers/lazy-distro-mirrors
cat <<EOF > /etc/containers/lazy-distro-mirrors/config.yaml
mirrors:
  debian.csail.mit.edu: http://debian.csail.mit.edu 
EOF
```

Make sure that the mirror you configure is the same one as
`debian-pxe-provision` is configured for.

Now start the lazy mirror on external port 80 (it needs to be the same port as
the original mirror URL.):

```
docker run \
  --name lazy-distro-mirrors \
  -d --restart=always \
  --publish 80:8080 \
  --volume /etc/containers/lazy-distro-mirrors:/docker_configurator/user \
  --volume lazy-distro-mirrors:/var/spool/squid \
enigmacurry/lazy-distro-mirrors
```

## Development loop

If you are me, or you are developing with docker-machine, here is a dev loop
that does all the following:

 * Copies the config.yaml and default_config files from local workstation to the
   server. (Creating paths if necessary.)
 * Builds the docker image.
 * Runs the container on the server

This assumes you have docker installed on your workstation and you are using a
remote docker server with an ssh config called `docker1`, [as outlined in the
parent
README.](https://github.com/PlenusPyramis/dockerfiles#mini-docker-development-tutorial)


```
ssh docker1 "mkdir -p /etc/containers/debian-pxe-provision" && \
   scp config.yaml docker1:/etc/containers/debian-pxe-provision/ && \
   rsync -avz --delete default_config docker1:/etc/containers/debian-pxe-provision/default_config && \
   docker build -t plenuspyramis/debian-pxe-provision . && \
   docker run --rm -it \
     --privileged \
     --network host \
     -v /etc/containers/debian-pxe-provision/config.yaml:/config/config.yaml \
     plenuspyramis/debian-pxe-provision
```
