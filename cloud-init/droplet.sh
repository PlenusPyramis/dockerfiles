#!/bin/bash

## This is a development tool for debugging cloud-init on DigitalOcean and
## automates droplet creation/destruction.

## First step is configure doctl on your system and setup the API key
## Follow guide: https://github.com/digitalocean/doctl#installing-doctl

## Second step configure your Float IP Address, Droplet name, and SSH KEY ID:
## (floating ip has to be setup from a prior droplet beforehand):

## Third step, source this file in your bash session.
## Then run functions to create and destroy the droplet.

export DROPLET_NAME=d
export FLOATING_IP=167.172.12.217
export SSH_KEY=26184694
export USER_DATA_FILE=traefik-photostructure.yaml

droplet_destroy() {
    DROPLET=$(doctl compute droplet list --format=ID,Name --no-header | grep " $DROPLET_NAME$" | cut -d " " -f 1)
    if [ -z "$DROPLET" ]
    then
        echo Droplet does not exist: $DROPLET_NAME
    else
        doctl compute droplet delete $DROPLET --force
        echo "Deleting droplet $DROPLET ..."
        sleep 10
    fi
}

droplet_create() {
    DROPLET=$(doctl compute droplet list --format=ID,Name --no-header | grep " $DROPLET_NAME$" | cut -d " " -f 1)
    if [ -z "$DROPLET" ]
    then
        echo Creating droplet $DROPLET_NAME ...
        DROPLET=$(doctl compute droplet create $DROPLET_NAME --size s-1vcpu-1gb --image docker-18-04 --region nyc1 --ssh-keys $SSH_KEY --user-data-file $USER_DATA_FILE --wait --no-header --format=ID)
        echo Assigning Floating IP to $DROPLET_NAME
        doctl compute floating-ip-action assign $FLOATING_IP $DROPLET
    else
        echo Droplet already exists: $DROPLET_NAME ID=$DROPLET
        return 1
    fi
}

droplet_ssh() {
    ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$FLOATING_IP "$@"
}

droplet_status() {
    droplet_ssh cloud-init status -w
    retVal=$?
    echo "Inspect the cloud-init logs by running droplet_logs"
    return $retVal
}

droplet_logs() {
    droplet_ssh cat /var/log/cloud-init-output.log | less
}

droplet_recreate() {
    droplet_destroy && droplet_create && echo "Waiting 30s before trying to connect ..." && sleep 30 && \
        echo "Checking cloud-init status ... " && droplet_status
}
