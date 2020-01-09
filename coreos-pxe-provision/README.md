# coreos-pxe-provision

A Fedora CoreOS PXE boot server in a docker container, local image caching, and
automatic ignition file generation, all from one config file.

Tested on Fedora CoreOS version: 30.20190725.0 (2019-07-25T18:54:22Z)

 * Edit [config.yaml](config.yaml) for your network environment.
 * Create `clients` entries inside [config.yaml](config.yaml) for all your clients MAC
   addresses, static ip address, and other per-client configs.
 * Only the clients listed will be offered DHCP/PXE boot. (This is a safety
   mechanism to help prevent accidentally installing on the wrong machine/vm.)
 * All of the config is in your [config.yaml](config.yaml) that you mount at container
   runtime. The coreos images/isos that you configure will be downloaded
   automatically and verified on the first container run, and served locally
   over HTTP for the (i)PXE clients to load.

At the moment this only supports BIOS machines, not UEFI. This works well for
KVM which is usually booted with SeaBIOS. UEFI cannot use pxelinux, which is the
tool used here to load the per-mac-address config file, so UEFI is unsupported
for now.

## Config 

The provided [config.yaml](config.yaml) is setup for EnigmaCurry's use. You can use it as an
example, but you'll need to change several settings according to your own
environment. Things you will maybe want to change in your own [config.yaml](config.yaml):

 * `ssh_keys` - A list of the ssh public keys to install in the core user
   account.
 * `interface` - The dnsmasq configuration is setup to bind to a specific host
   network interface (see list by running `ip addr` on the same machine running
   docker). It will run DHCP/DNS/TFTP/HTTP services on this interface. You want
   to find the interface that has the IP that your clients can access. The main
   interface is usually called `eth0` or `eno1`, but can vary widely, so double
   check. If you're running docker inside a VM, this is the name of the main
   network interface inside that VM.
 * `public_ip` - This is the ip address of the interface on the host. Check `ip addr`.
 * `dhcp`
   * `subnet` - the IP subnet of the network to service DHCP requests.
   * `gateway` - The IP address for the gateway for the clients.
 * `autoinstall` - This is turned off by default, when clients boot they will
   stop at the bootloader screen waiting for input. Setting
   `autoinstall.enabled` to true will automatically boot the given
   `autoinstall.entry` number (from `menu_entries`, starting at 0 for the first
   one).
 * `clients` - A map of MAC addresses to client configurations.
     * (key) MAC address of client machine.
     * `hostname` the hostname to give the client.
     * `ip_address` the static ip address to give the client.
     * `interface` the name of the main ethernet interface of the client.
     * `install_dev` the device name to install on (omit `/dev/`).
     * `vga` set to true to use VGA console, otherwise default to serial console.
     * `units` which systemd units to install from templates.

## Known bugs

[NetworkManager will not work correctly on the first
boot](https://github.com/coreos/fedora-coreos-tracker/issues/233). It loads the
wrong config. Rebooting a *second time* after install should fix it. The builtin
configuration accounts for this and does a total of two reboots during install.

## Dev loop

This is a pre-constructed command that does all of the following:

 * Make directory called /etc/containers/coreos-pxe-provision on docker server
 * Copy the [config.yaml](config.yaml) and default_config to the server
 * Build the docker image
 * Run the docker container with config and mounts

(assumes that docker-machine is used to be able to use docker from local
workstation. See [parent docs](../README.md))

```
DOCKER_MACHINE=pxe-provision && \
    ssh ${DOCKER_MACHINE} "mkdir -p /etc/containers/coreos-pxe-provision/{images,isos}" && \
    scp config.yaml ${DOCKER_MACHINE}:/etc/containers/coreos-pxe-provision/ && \
    rsync -avz --delete default_config ${DOCKER_MACHINE}:/etc/containers/coreos-pxe-provision/default_config && \
    docker build -t plenuspyramis/coreos-pxe-provision . && \
    docker run --name pxe-provision \
        --rm -it --privileged  --network host \
        -v /etc/containers/coreos-pxe-provision/config.yaml:/config/config.yaml \
        -v /etc/containers/coreos-pxe-provision/isos:/data/isos \
        -v /etc/containers/coreos-pxe-provision/images:/data/images \
        plenuspyramis/coreos-pxe-provision
```
