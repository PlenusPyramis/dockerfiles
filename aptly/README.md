# docker-aptly

Start aptly service:

```
docker run \
  --detach=true \
  --restart=always \
  --name="aptly" \
  --publish 80:80 \
  --volume aptly:/opt/aptly \
  --env FULL_NAME="Ryan McGuire" \
  --env EMAIL_ADDRESS="ryan@plenuspyramis.com" \
  --env GPG_PASSWORD="PickAPassword" \
  --env HOSTNAME=aptly.app.lan.rymcg.tech \
  plenuspyramis/aptly
```

Configure a partial debian mirror, enough to install a minimal server:

```
docker exec -it aptly /opt/update_mirror_debian.sh
```

___

* Copyright 2019 PlenusPyramis
* Copyright 2018-2019 Artem B. Smirnov
* Copyright 2016 Bryan J. Hong
* Licensed under the Apache License, Version 2.0
