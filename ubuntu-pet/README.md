# Ubuntu Pet

This is a VPS style pet container with an SSH(+MOSH) server.

[Normally, starting an SSH service in a docker container is
wrong.](https://jpetazzo.github.io/2014/06/23/docker-ssh-considered-evil/)

However, a pretty good argument can be made for using a docker container as a
development environment. In this mode, having a persistent stateful environment
that you can have a normal connection to is exactly what you want. 

This is not recommended for any production role.

## Running Rootless with Podman

Podman will let you run this container without needing docker, and without
needing root access.

### Build the container image

```
podman build -t ubuntu-pet .
```

(you can name it something other than ubuntu-pet if you wish.)

Create a new `authorized_keys_ubuntu_pet` file to list the allowed ssh keys for
the root user inside the ubuntu-pet container. I keep this in
`$HOME/.ssh/authorized_keys_ubuntu_pet` but you can keep it wherever you like. I
just make a copy of my regular `authorized_keys` file because I already have
keys setup on this machine for the normal host ssh server:

```
cp $HOME/.ssh/authorized_keys $HOME/.ssh/authorized_keys_ubuntu_pet
```

You must copy all of the public ssh keys into this file that you wish to have
access to the container.

### Create directory to store persistent host keys, and run the container

```
mkdir -p $HOME/.ssh/ubuntu_pet_keys && podman run --name ubuntu-pet --rm -d -p 2222:22 -p 60000-60010:60000-60010/udp -v $HOME/.ssh/ubuntu_pet_keys:/etc/ssh/keys:Z -v $HOME/.ssh/authorized_keys_ubuntu_pet:/root/.ssh/authorized_keys:Z ubuntu-peto
```

 * Note that `--rm` will remove the container (and all files created inside)
   when the container exists. If you want a persistent container, you can remove
   the `--rm` and use `podman stop ubuntu-pet` and `podman start ubuntu-pet`
   (even after host reboot), but please note that all files would be destroyed
   if you ran `podman rm ubuntu-pet`, unless you mount your own extra volumes.
 * `--name ubuntu-pet` is the name for the container, you can choose a different
   name if you wish.
 * Note that `mkdir -p` will only attempt to create a directory if it doesn't
   already exist, so you can run this everytime you want to start the container.
 * `-p 2222:22` allows SSH access to the container, it maps the host TCP port
   2222 to the container port 22.
 * `-p 60000-60010:60000-60010/udp` allows MOSH access to the container, it maps
   a range of UDP ports.
 * `-v $HOME/.ssh/ubuntu_pet_keys:/etc/ssh/keys:Z` mounts the persistent
   host-keys directory (if this is not used, it will generate new host-keys
   everytime the container starts)
 * `-v $HOME/.ssh/authorized_keys_ubuntu_pet:/root/.ssh/authorized_keys:Z`
   mounts the authorized ssh public keys allowed to connect to the container.
   Access will be denied unless your key is listed in this file.
 * The final `ubuntu-pet` is the image name you built above.

### Test that ssh works

```
ssh root@localhost -p 2222
```

### Test that mosh works

```
mosh --port 60000:60000 --ssh="ssh -p 2222" root@localhost
```
