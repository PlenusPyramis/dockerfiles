# Cloud-Init

A collection of [cloud-init](https://cloudinit.readthedocs.io/) scripts for
docker servers.

All files are made available under the terms of this [MIT License](../LICENSE)

##  Docker + Traefik + Let's Encrypt on Digital Ocean

This shows step-by-step instructions for how to deploy Docker with Traefik on a
Digital Ocean droplet using only the Digital Ocean control panel. Usage of the
terminal command line is only required for debugging things if things don't work
the way they should.

Before getting started, you will need to check and prepare the following:

 * A [Digtal Ocean account](https://m.do.co/c/069af06b869e) (get a $100 credit
   in your account for using my referral link.)
 * A registered internet domain name, and the ability to change the DNS records.
 * An email address to give to Lets Encrypt when certificates are generated.
 * Choose a subdomain to dedicate to this droplet: For instance, if you have
   `example.com` you might choose `d.example.com` (d for docker, and its short.)
   It is not recommended to use the root of the domain (`example.com`) because
   if you did, you would not be able to create more than one droplet and use the
   same domain. Hosted apps will be used under the subdomain you choose, eg.
   `whoami.d.example.com` for the included `whoami` app.

### One time setup for Block Storage, Floating IP address, and DNS

You need an external block storage volume to save the Traefik certificates file
(`acme.json`). You need a floating IP address to create your DNS record for.

You will create a temporary droplet for the sole purpose of preparing this block
storage volume with a unique name, and then destroying the temporary droplet.
Digital Ocean does not let you create a volume without someplace to attach it
to, so that is why the temporary droplet is necessary.

Open the [droplet creation
page](https://cloud.digitalocean.com/droplets/new?i=e2813f&size=s-1vcpu-1gb&region=nyc3&appId=50944795&type=applications).

Change the following settings:

 * Choose the same datacenter as you wish to create your permanent droplet in.
 * Click `New SSH Key` and follow the directions, or if you already have a key
   setup you can select the key.
 * Change the hostname to `temp1`.
 * None of the other settings matter for this, since we're deleting it anyway.
 * Click Create Droplet.
 
Wait for the droplet to finish creating, then navigate to the `Volumes` tab on the left hand menu.

 * Click `Create Volume`
 * Select a custom volume size and enter `1GB` (the smallest possible size)
 * Select the `temp1` droplet to attatch it to.
 * Enter the volume name: `volume-nyc3-traefik-config` (use your datacenter name
   instead of `nyc3` if different.) You will need to remember the exact volume
   name you choose for the next part!
 * Click `Create Volume`.
 
Now go to the `Networking` tab on the left hand menu.

 * Click the `Floating IPs` tab.
 * In the search box find the `temp1` droplet and click `Assign Floating IP`.
 
Now go to your DNS control panel (this might not be on Digital Ocean, and will
be different depending on your configuration of your domain name, so these are
generic instructions)

 * Create a DNS A record for the subdomain you chose (eg. `d.example.com`) and
   use the Floating IP address you created.
 * Create a DNS A Wildcard record for all sub-sub-domains (eg.
   `*.d.example.com`) and use the Floating IP address you created.
 
Ensure that the DNS records are working by using the [Dig
tool](https://toolbox.googleapps.com/apps/dig/). Enter your subdomain and any
sub-sub-domain and it should resolve to the Floating IP address.
 
Now navigate back to the `Droplets` tab on the left hand menu.

 * Destroy the `temp1` droplet, by finding the droplet in the list, clicking `More` and then `Destroy`.
 * Notice that the volume and floating IP address persist, even after the
   temporary droplet is destroyed, and can now be attached to a new droplet.

### Creating your droplet

Open the droplet creation page [using these
settings](https://cloud.digitalocean.com/droplets/new?i=e2813f&size=s-1vcpu-1gb&region=nyc3&appId=50944795&type=applications). By using that link you get some things pre-populated for you:

 * Preselects the Docker Marketplace App. 
 * Preselects the $5/month droplet size.
 
There are still several things you need to change on this screen:

 * Click `Add volume` and choose `Attach existing` and select the same volume you created above.
 * Choose a datacenter for your droplet.
 * Select the SSH key you previously created.
 * Choose a hostname, I recommend it is the same as the first part of the subdomain name (eg. `d`).
 * Under `Select additional options` check the box for `User data`.
 * In the box that appears you need to paste in your cloud-init User data. This is described next.
 
The User data is where you paste your cloud-init config. This is where you
configure traefik and set your subdomain, email address, volume name etc. It
also pulls other configs from this repository and builds a complete
configuration for your droplet, and will finish all of the installation for you,
hands free.

Copy and paste ALL of the following text into the `User data` field:

```
Content-Type: multipart/mixed; boundary="===============2524101902564364365=="
MIME-Version: 1.0

--===============2524101902564364365==
Content-Type: text/cloud-config; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="user_variables.yaml"

#cloud-config

write_files:
  - path: /run/cloud-init/user-variables-sensitive.yaml
    content: |
      traefik:
        ## Set your subdomain here:
        domain: d.example.com
        ## Set your email address here:
        email: you@example.com
        ## Set the volume name that you created for traefik:
        acme_volume: volume-nyc3-traefik-config
        ## It is more secure to leave the traefik dashboard turned off, you probably don't need it:
        dashboard_enable: false
        ## If you do turn on the dashboard, it will use this username:
        username: traefik
        ## If you do turn on the dashboard, it will use this password:
        password: traefik

--===============2524101902564364365==
Content-Type: text/x-include-url; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="traefik_includes.txt"

#include
https://raw.githubusercontent.com/PlenusPyramis/dockerfiles/master/cloud-init/traefik.yaml


--===============2524101902564364365==--
```

The format of this text may look strange. The very first line should start with
`Content-Type` and the very last line should end with
`--===============2524101902564364365==--`. You need to copy the whole thing in
order for it to work.

The only part you need to change is the part in the middle under the `traefik:`
line under `write_files`. This is where you need to set your domain name, email,
and acme volume name.

Once you have copied that text into the `User data` field on the droplet
creation page, and you have made any necessary edits, now click the `Create
Droplet` button.

Once the droplet has started, on the droplet details page you can assign the
Floating IP address to the new droplet.

### Checking things are working

Give the droplet a few minutes in order to start. Once it is up, you should be
able to open your web browser and enter the URL for the test page. That URL is
based off of the domain you set in your User data config above. According to the
example, the URL you want to open would be https://whoami.d.example.com - this
page will display some debug text information giving you your IP address among
other details. If the page says "404" or another type of error give it a few
more minutes and check back again. Also check in the browser URL bar that the
SSL certificate looks right, the issuer should be `Let's Encrypt Authority X3`.

If the page still does not come up, you can check the cloud-init logs by using
SSH into the droplet.

On your local laptop/workstation run ssh:

```
ssh root@d.example.com
```

Once logged into the droplet, you can check on the cloud-init status:

```
cloud-init status -w
```

You should see a final message like `done` or `error`. If cloud-init hasn't
finished yet, you will see a series of growing dots until it finishes.

If there are problems, you can check the output in the log file: 

```
cat /var/log/cloud-init-output.log
```

### Maintenance

You can maintain your droplet through SSH. All of the config is stored locally
on the droplet in the directory `/opt/containers`. The docker-compose for
traefik is in `/opt/containers/traefik/docker-compose.yaml` and the traefik
config file is in `/opt/containers/traefik/data/traefik.yaml`. Create new apps
by creating new directories in `/opt/containers` and put new docker-compose
files there.

[Learn more about docker-compose](https://docs.docker.com/compose/) including
how to start, stop, and recreate containers.

### Even more automation

If you like this style of configuration, and find yourself creating droplets
repeatedly trying out new things, you should check out the [included developer
tool](./droplet.sh) - which automates all of the repetitive steps of destroying
and recreating the droplet. It utilizes the official Digital Ocean command line
utility [doctl](https://github.com/digitalocean/doctl) invoked from your
laptop/workstation. Instructions are listed at the top of the file.
