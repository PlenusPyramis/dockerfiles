# dnsmasq

DNS / DHCP / TFTP server

Includes PXE boot for debian-stretch netboot.

Assuming you have a dnsmasq configuration in `$HOME/dnsmasq.conf`, you can start
the container like so:

```
sudo docker run --rm -it --privileged --network host -v $HOME/dnsmasq.conf:/etc/dnsmasq.conf plenuspyramis/dnsmasq
```

`--privileged` and `--network host` are only required if you want to bind to a
real host network interface, which I usually do.

## Setup Laptop as temporary DHCP server for raspberry pi

If you already have a wired ethernet router setup, just plug the raspberry pi
in, get the IP address, and ssh in. If that works for you, great. You don't need
to read this section.

Otherwise, you have a problem. You can grab a keyboard/monitor and plug them
into the raspberry, and configure wifi. Don't have those things? Continue on..

You can plug an ethernet cable directly between your laptop and the raspberry
pi. If you assign static IP addresses to both sides, you can connect directly
via wired ethernet. Except, unless you've already setup a static IP on the
raspberry pi, it's expecting to get an automatic IP via DHCP.

So you can run a DHCP server on your laptop in a docker container. Don't worry,
it's not as hard as it sounds.

Note that this setup will not provide internet access to the raspberry pi, but
only a point to point connection between your laptop and the raspberry. But this
is often enough, and is a way to login, and configure the raspberry's wifi
without plugging in a keyboard/monitor.

Make sure your laptop is connected to the internet via WiFi and has its ethernet
port free. 

Install Docker on your laptop.

Identify the name of your wired ethernet adapter:

```
ip link
```

Adapter names will vary depending on your kernel and OS, but mine is called
`enp0s25`.

Disable your normal ethernet DHCP settings. Assign a static ip address instead:
`192.168.16.1` with netmask `255.255.255.0` - Instructions for this vary widely
depending on your OS. (Likely you have a network-manager applet in your system
tray you can use for this. Otherwise check your distro documentation.)

**Now plug an ethernet cable directly between your laptop's ethernet port and the
raspberry pi.**

Double check that your wired adapter is now assigned the static ip address
`192.168.16.1`:

```
ip addr
```

Create a dnsmasq configuration on your laptop in your home directory:

```
cat <<EOF > $HOME/dnsmasq_temp.conf
## Only bind to the given interface:
interface=enp0s25
bind-interfaces

## Setup DNS servers
no-resolv
server=1.0.0.1
server=1.1.1.1
strict-order

## Service DHCP requests:
dhcp-range=192.168.16.100,192.168.16.150,255.255.255.0,12h
no-daemon
EOF
```

Start the container using the config file:

```
sudo docker run --rm -it --privileged --network host -v $HOME/dnsmasq_temp.conf:/etc/dnsmasq.conf plenuspyramis/dnsmasq
```

Now you should see output from the dnsmasq process, like so:

```
dnsmasq: started, version 2.80 cachesize 150
dnsmasq: compile time options: IPv6 GNU-getopt no-DBus no-i18n no-IDN DHCP DHCPv6 no-Lua TFTP no-conntrack ipset auth no-DNSSEC loop-detect inotify dumpfile
dnsmasq-dhcp: DHCP, IP range 192.168.16.100 -- 192.168.16.150, lease time 12h
dnsmasq-dhcp: DHCP, sockets bound exclusively to interface enp0s25
dnsmasq: using nameserver 1.1.1.1#53
dnsmasq: using nameserver 1.0.0.1#53
dnsmasq: read /etc/hosts - 5 addresses
dnsmasq-dhcp: DHCPDISCOVER(enp0s25) xx:xx:xx:xx:xx:xx 
dnsmasq-dhcp: DHCPOFFER(enp0s25) 192.168.16.125 xx:xx:xx:xx:xx:xx 
dnsmasq-dhcp: DHCPREQUEST(enp0s25) 192.168.16.125 xx:xx:xx:xx:xx:xx 
dnsmasq-dhcp: DHCPACK(enp0s25) 192.168.16.125 xx:xx:xx:xx:xx:xx ubuntu
```

Explanation of the output:

 * `DHCPDISCOVER` - the raspberry pi broadcasts that it wants to find DHCP servers.
 * `DHCPOFFER` - dnsmasq responds, offering the ip address of `192.168.16.125`.
 * `DHCPREQUEST` - the raspberry pi formally requests the offered ip address.
 * `DHCPACK` - dnsmasq acknowledges, registering the ip address to the mac
   address of the raspberry pi.
 
If you don't see any `DHCPDISCOVER` line, try unplugging the ethernet cable and
plugging it back in.

Press Ctrl-C to quit the dnsmasq process. It does not need to stay running.
However, if you reboot the raspberry pi, you will need to restart dnsmasq again
temporarily.

Now you can ssh to the raspberry pi from the laptop, using the ip address listed
in the dnsmasq output.
 
