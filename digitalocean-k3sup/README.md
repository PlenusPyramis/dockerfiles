# digitalocean-k3sup

NOTE: This doesn't work yet, this doc describes how it *will* work.

This is a container that will create a remote Digital Ocean
[k3s](https://k3s.io/) cluster utilizing the [golang API binding for
digitalocean](https://github.com/digitalocean/godo) and
[k3sup](https://github.com/alexellis/k3sup).

[Sign up for Digital Ocean with this referral link and get $100 credit in your
account.](https://m.do.co/c/069af06b869e)

## Running the container

This container is a command line client with programmatic or interactive
configuration. It can be run from anywhere that you have console access to a
docker instance. The k3s cluster is created externally in the chosen Digital
Ocean datacenter using k3sup.

Run it interactively and just follow the prompts:

```
docker run --rm -it plenuspyramis/digitalocean-k3sup --interactive
```

Or run it programmatically and pass all the answers via environment variable:

```
docker run --rm -t plenuspyramis/digitalocean-k3sup \
    -e DO_API_KEY=Your-API-Key-Here \
    -e CLUSTER_SIZE=1 \
    -e CLUSTER_REGION=nyc3
    -e MACHINE_SIZE=s-1vcpu-1gb
```

The application will ask you questions including:

 * Your Digital Ocean API Key. You must generate this in your own account on the
   API tab.
 * The size of the cluster, ie. how many droplets to create.
 * The machine size, ie. the droplet size name (see `doctl compute size list`)
 
