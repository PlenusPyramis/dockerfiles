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
docker, and without needing root access. Inside of the container, you will have
full root access, and you can create additional accounts, install packages, etc.

### Build the container image

Clone this repository and build the image :

```
git clone https://github.com/PlenusPyramis/dockerfiles.git $HOME/git/vendor/plenuspyramis/dockerfiles
cd $HOME/git/vendor/plenuspyramis/dockerfiles
podman build -t ubuntu-pet .
```

(you can name it something other than ubuntu-pet if you wish.)

### Create Authorized Keys file

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
mkdir -p $HOME/.ssh/ubuntu_pet_keys && \
podman run --name ubuntu-pet --rm -d \
    -p 2222:22 -p 60000-60010:60000-60010/udp \
    -v $HOME/.ssh/ubuntu_pet_keys:/etc/ssh/keys:Z \
    -v $HOME/.ssh/authorized_keys_ubuntu_pet:/root/.ssh/authorized_keys:Z \
    ubuntu-pet
```

### Explanation of podman run command arguments:

 * Note that `--rm` will remove the container (and all files created inside)
   when the container stops. If you want a persistent container, you can remove
   the `--rm` and use `podman stop ubuntu-pet` and `podman start ubuntu-pet`
   (even after host reboot), but please note that all files would be destroyed
   if you ran `podman rm ubuntu-pet`, unless you mount your own extra volumes.
 * `--name ubuntu-pet` is the name for the container, you can choose a different
   name if you wish.
 * Note that `mkdir -p` will only attempt to create a directory if it doesn't
   already exist, so you can run this everytime you want to start the container.
 * `-p 2222:22` allows SSH access to the container on the host port 2222.
 * `-p 60000-60010:60000-60010/udp` allows MOSH access to the container, it maps
   a range of UDP ports. Mosh by default uses the range of 60000-61000, however
   I found I do not need more than 10 ports so I expose fewer.
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
