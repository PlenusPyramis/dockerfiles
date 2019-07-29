# dockerfiles

![containers.jpg](containers.jpg)


## Mini docker development tutorial

You need `docker-ce engine` installed on your workstation/laptop, even if you only
plan to use docker on remote servers:

 * [Install docker-ce engine](https://docs.docker.com/install/linux/docker-ce/ubuntu/)

You need to install `docker-machine` in order to remotely install/control docker on servers:

 * [Install docker-machine](https://docs.docker.com/machine/install-machine/)

Create a server to run docker. It could be a Virtual Machine, a cloud instance,
a raspberry pi, whatever. **You don't need to install docker on the server
yourself.** Just install stock Ubuntu / Debian / Raspbian or something else
standard. Setup SSH and your keys for the `root` user.

On your workstation, create an ssh client config for the server. Edit
`~/.ssh/config`

```
## Replace example.com with your server's domain name or IP address:
Host docker1
    Hostname example.com
    User root
```

On your workstation, make sure you have an ssh key:

```
test -f ~/.ssh/id_rsa_test && echo "already setup" || ssh-keygen -f ~/.ssh/id_rsa_test
```

If your server does not yet have your SSH key, install it (you will be prompted
to enter the server's root passphrase one time:)

```
ssh-copy-id docker1
```

Now test that you can login to the server:

```
ssh docker1
```

It should not ask for any passphrase. If it asks for a passphrase for your ssh
key, it means that you told `ssh-keygen` to use a passphrase, but that you don't
have an ssh agent setup/running to cache your passphrase. Setup an SSH agent, or
create a new key without a passphrase.

Once you've tested that ssh is working, you can install docker!

On your workstation, use `docker-machine` to remotely setup the server and
install docker with one line:

```
docker-machine create -d generic --generic-ip-address X.X.X.X docker1
```

Replace `X.X.X.X` with the public IP address of your server.

Now setup your current terminal session to use the remote docker instance:

```
eval $(docker-machine env docker1)
```

Run `docker version` and you should see both client and server versions listed.

Run `docker info | grep Name:` and you should see the name `docker1`.

Run `docker ps` and you should see an empty list of containers on your fresh
docker server.

Now just use docker commands normally and it will execute on `docker1`.

In order to preserve your environment in new terminal sessions, and to always
use the remote docker server, add the following to your `~/.bashrc`:

```
eval $(docker-machine env docker1)
```

