# Ubuntu Pet

This is a VPS style pet container with an SSH(+MOSH) server.

[Normally, starting an SSH service in a docker container is
wrong.](https://jpetazzo.github.io/2014/06/23/docker-ssh-considered-evil/)

However, a pretty good argument can be made for using a docker container as a
development environment. In this mode, having a persistent stateful environment
that you can have a normal ssh connection to, is exactly what you want. Another
good role is for a bastion/jump server, using this container you can use MOSH to
connect to other machines that don't have MOSH installed, for example.

This is not recommended for any production service role.

## Running Rootless with Podman

Podman will let you run this container on your host system, without needing
docker, and without needing root access. Systemd can automatically start your
containers when the host system boots. Inside of the container, you will have
full root access, and you can create additional user accounts, install packages,
etc.

### Run the container (without systemd):

```
mkdir -p $HOME/.ssh/ubuntu-pet && \
podman run --name ubuntu-pet --rm -d \
    -p 2222:22 -p 60000-60010:60000-60010/udp \
    -v $HOME/.ssh/ubuntu-pet:/etc/ssh/keys \
    -v $HOME/.ssh/authorized_keys:/root/.ssh/authorized_keys:ro \
    plenuspyramis/ubuntu-pet
```

### Explanation of podman run command arguments:

 * The `$HOME/.ssh/ubuntu-pet` directory is created to store the SSH host keys
   that container creates. (`mkdir -p` only creates the directory if it doesn't
   exist already, so it is safe to always run the mkdir as part of this
   command.)
 * Note that `--rm` will remove the container (and all files created inside)
   when the container stops. If you want a persistent container, you can remove
   the `--rm` and the container will persist after it stops. Then you can use
   `podman start ubuntu-pet` and `podman stop ubuntu-pet` (even after a host
   reboot), but please note that all files would be destroyed if you ran `podman
   rm ubuntu-pet`, unless you mount your own extra volumes.
 * `--name ubuntu-pet` is the name for the container, you can choose a different
   name if you wish.
 * `-p 2222:22` allows SSH access to the container on the host port 2222.
 * `-p 60000-60010:60000-60010/udp` allows MOSH access to the container, it maps
   a range of UDP ports. Mosh by default uses the range of 60000-61000, however
   I found I do not need more than 10 ports so I expose fewer.
 * `-v $HOME/.ssh/ubuntu-pet:/etc/ssh/keys` mounts the persistent host-keys
   directory (if this is not mounted, it will generate new host-keys everytime
   the container starts)
 * `-v $HOME/.ssh/authorized_keys:/root/.ssh/authorized_keys:ro` mounts the
   authorized ssh public keys allowed to connect to the container. Access will
   be denied unless your key is listed in this file. This example uses the same
   authorized_keys file from the host SSH service. You can use a seperate file
   if you wish the access to be different for the container than for the host.
 * The final `plenuspyramis/ubuntu-pet` tells podman to use the prebuilt image
   from the docker hub, but you can instead build and use your own image
   locally.

### Test that ssh works

```
ssh root@localhost -p 2222
```

You can also put the following config in `$HOME/.ssh/config` :

```
Host ubuntu-pet
    Hostname 127.0.0.1
    User root
    Port 2222
```

(change `127.0.0.1` accordingly if you are connecting from a different host)

Then just run `ssh ubuntu-pet`

### Test that mosh works

```
mosh --port 60000 --ssh="ssh -p 2222" root@localhost
```

If you put `ubuntu-pet` into your ssh config, you can simply run:

```
mosh ubuntu-pet
```

### Automate startup with systemd

You can use systemd to start the container on system boot. Copy (or symlink) the
`ubuntu-pet.service` file into the directory `$HOME/.config/systemd/user`
(create the directory if it does not exist.)

Enable systemd "lingering" for your account. This will allow systemd to
automatically start your user services on bootup (you only need to run this once
ever):

```
loginctl enable-linger
```

Now enable and start the ubuntu-pet service:

```
systemctl --user enable --now ubuntu-pet
```

And check on its status:

```
systemctl --user status ubuntu-pet
```

You can start/stop the service manually too:

```
systemctl --user stop ubuntu-pet
systemctl --user start ubuntu-pet
```

Reboot the host in order to test that the service is started automatically on
boot.

