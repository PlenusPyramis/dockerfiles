# menu-pxe-provision

A menu-driven PXE boot server

 * Edit config.yaml
 * Copy ISOs to server /etc/containers/menu-pxe-provision/isos
 * Copy images to server /etc/containers/menu-pxe-provision/images

```
ssh pxe-provision "mkdir -p /etc/containers/menu-pxe-provision" && \
    scp config.yaml pxe-provision:/etc/containers/menu-pxe-provision/ && \
    rsync -avz --delete default_config pxe-provision:/etc/containers/menu-pxe-provision/default_config && \
    docker build -t plenuspyramis/menu-pxe-provision . && \
    docker run --name pxe-provision \
    --rm -it --privileged  --network host \
    -v /etc/containers/menu-pxe-provision/config.yaml:/config/config.yaml \
    -v /etc/containers/menu-pxe-provision/isos:/data/isos \
    -v /etc/containers/menu-pxe-provision/images:/data/img \
    plenuspyramis/menu-pxe-provision
```
