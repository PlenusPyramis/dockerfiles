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

