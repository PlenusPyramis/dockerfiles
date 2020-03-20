# Ubuntu Pet

This is a VPS style pet container with an SSH(+MOSH) server.

[Normally, starting an SSH service in a docker container is
wrong.](https://jpetazzo.github.io/2014/06/23/docker-ssh-considered-evil/)

However, a pretty good argument can be made for using a docker container as a
development environment, and having a normal SSH connection to that environment
is often ideal for tools like Ansible or Emacs' TRAMP. Another good role is for a
bastion/jump server; using this container you can use MOSH to connect to other
machines that don't have MOSH installed, for example.

This is not recommended for any production service role.

## Running Rootless with Podman

Podman will let you run this container on your host system, without needing
docker, and without needing root access. Systemd can automatically start your
containers when the host system boots. Inside of the container, you will have
full root access, and you can create additional user accounts, install packages,
etc.

### Run the container (without systemd):

Basic command you would run if you don't want to use systemd:

```
mkdir -p $HOME/.ssh/ubuntu-pet/root && \
touch $HOME/.ssh/ubuntu-pet/root/authorized_keys && \
chmod 0600 $HOME/.ssh/ubuntu-pet/root/authorized_keys && \
podman run --rm -d --name ubuntu-pet --hostname ubuntu-pet \
    -p 2222:22 -p 60000-60010:60000-60010/udp \
    -v $HOME/.ssh/ubuntu-pet:/etc/ssh/keys:Z \
    plenuspyramis/ubuntu-pet
```

Each user that you create inside the container gets its own `authorized_keys`
file stored on the host in your home directory:
`$HOME/.ssh/ubuntu-pet/$USER/authorized_keys`. Password authentication is
disabled, so you must create and populate the `authorized_keys` file for the
root user, as well as for any other user accounts you need. If you already have
SSH keys setup for your host account, you can just copy from that into the root
`authorized_keys`:

```
cat $HOME/.ssh/authorized_keys > $HOME/.ssh/ubuntu-pet/root/authorized_keys
```

### Explanation of podman run command arguments:

 * Note that podman `--rm` will remove the container (and all files created
   inside) when the container stops. If you want a persistent container, you can
   remove the `--rm` and the container will persist after it stops. Then you can
   use `podman start ubuntu-pet` and `podman stop ubuntu-pet` (even after a host
   reboot), and note that all files would be destroyed if you ran `podman rm
   ubuntu-pet`, unless you mounted your own external volumes. I do not run my
   own containers this way, so I wish to keep the `--rm` for myself. See
   [Stateless](#stateless) for more information.
 * `--name ubuntu-pet` is the name for the container, you can choose a different
   name if you wish.
 * `--hostname ubuntu-pet` is the hostname for the container, you can choose a
   different hostname if you wish.
 * `-p 2222:22` allows SSH access to the container on the host port 2222.
 * `-p 60000-60010:60000-60010/udp` allows MOSH access to the container, it maps
   a range of UDP ports. Mosh by default uses the range of 60000-61000, however
   I found I do not need more than 10 ports so I expose fewer.
 * `-v $HOME/.ssh/ubuntu-pet:/etc/ssh/keys` mounts the persistent host-keys and
   user authorized_keys directory. 
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
[ubuntu-pet.service](https://raw.githubusercontent.com/PlenusPyramis/dockerfiles/master/ubuntu-pet/ubuntu-pet.service)
file into the directory `$HOME/.config/systemd/user` (create the directory if it
does not exist.)

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

### Stateless 

As discussed earlier, podman is running the container with `--rm` which means
that any files you edit that you have not mapped to an external volume,
(including any packages that you install with apt-get etc.) are LOST whenever
the container stops or restarts. This is my preferred way of working with
containers, because it means that I always start from a known clean base image.
If I need to add packages, or create a new user, I create a new Dockerfile and
build a new image based from this.

For example, create a new file called `Dockerfile-ryan`:

```
FROM plenuspyramis/ubuntu-pet

RUN apt-get update -y && \
    apt-get install -y zsh && \
    useradd -m ryan --shell /bin/zsh
```

Build the container image:

```
podman build -t ubuntu-ryan -f Dockerfile-ryan
```

Now change the `IMAGE` variable in the systemd service file to `ubuntu-ryan`
(instead of `plenuspyramis/ubuntu-pet`) and restart the service. Your container
will now have a `ryan` account available and `zsh` installed. This is how you
can build whatever sort of container image you want.
