#!/bin/bash

## This is a development tool for debugging cloud-init on DigitalOcean and
## automates droplet creation/destruction.

## First step is configure doctl on your system and setup the API key
## Follow guide: https://github.com/digitalocean/doctl#installing-doctl

## Second step configure below: your Droplet name, region, floating IP address,
## SSH key fingerprints, the Volumes to mount, and the User Data cloud-config
## file (Volume must be created by hand beforehand. Floating IP address must be
## setup from a prior droplet beforehand.)

## Third step, source this file in your bash session.
## Then run functions to create and destroy the droplet, view the logs, or run SSH.

export DROPLET_REGION=nyc1
export DROPLET_NAME=d
export DROPLET_IMAGE=docker-18-04
export DROPLET_SIZE=s-1vcpu-1gb
export FLOATING_IP=167.172.12.217
export SSH_FINGERPRINTS=76:ef:9f:d2:36:c9:c1:36:79:a5:8c:15:fb:bc:d8:64,e6:ac:de:dc:41:63:d6:56:b7:d2:ee:c3:56:b8:4e:47
export VOLUME_NAMES=volume-nyc1-traefik-config
export USER_DATA_FILE=test-multipart-mime.txt

droplet_destroy() {
    (
        set -e
        DROPLET=$(doctl compute droplet list --format=ID,Name --no-header | grep " $DROPLET_NAME$" | cut -d " " -f 1)
        if [ -z "$DROPLET" ]
        then
            echo Droplet does not exist: $DROPLET_NAME
        else
            doctl compute droplet delete $DROPLET --force
            echo "Deleting droplet $DROPLET ..."
            sleep 10
        fi
    )
    return $?
}

droplet_create() {
    (
        set -e
        ## Get Volume IDS
        VOLUMES=""
        IFS=',' read -ra NAMES <<< "$VOLUME_NAMES"
        for name in "${NAMES[@]}"; do
            VOLUMES=$(doctl compute volume list --no-header | grep " $name " | cut -d ' ' -f 1),$VOLUMES
        done
        VOLUMES=$(echo $VOLUMES | sed 's/,*$//' | sed 's/^,*//')

        ## Create droplet
        DROPLET=$(doctl compute droplet list --format=ID,Name --no-header | grep " $DROPLET_NAME$" | cut -d " " -f 1)
        if [ -z "$DROPLET" ]
        then
            echo Creating droplet $DROPLET_NAME ...
            DROPLET=$(doctl compute droplet create $DROPLET_NAME --size $DROPLET_SIZE --image $DROPLET_IMAGE --region $DROPLET_REGION --volumes $VOLUMES --ssh-keys $SSH_FINGERPRINTS --user-data-file $USER_DATA_FILE --wait --no-header --format=ID)
            test $? -eq 0 || exit 1
            echo Assigning Floating IP to $DROPLET_NAME
            doctl compute floating-ip-action assign $FLOATING_IP $DROPLET
        else
            echo Droplet already exists: $DROPLET_NAME ID=$DROPLET
            return 1
        fi
    )
    return $?
}

droplet_ssh() {
    ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$FLOATING_IP "$@"
}

droplet_status() {
    droplet_ssh "cloud-init status -w && cat /var/run/cloud-init/result.json | jq .v1.errors"
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
