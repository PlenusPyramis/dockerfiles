#!/bin/sh

#DOCKER=docker
DOCKER="docker -H ssh://root@159.203.77.80"
IMAGE=plenuspyramis/k3sup

DOCTL_VERSION=1.37.0
GOLANG_VERSION=1.13.6

exe() { ( echo "## $*"; $*; ) }

build() {
    exe $DOCKER build --build-arg DOCTL_VERSION=$DOCTL_VERSION --build-arg GOLANG_VERSION=$GOLANG_VERSION --tag $IMAGE .
}

shell() {
    exe $DOCKER run --rm -it -v /opt/containers/k3sup/data:/app $IMAGE /bin/bash 
}

(
    set -e
    $*
)
