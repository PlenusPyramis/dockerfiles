# Ubuntu Pet

This is a VPS style pet container with an SSH server.

[Normally, starting an SSH service in a docker container is
wrong.](https://jpetazzo.github.io/2014/06/23/docker-ssh-considered-evil/)

However, a pretty good argument can be made for using docker for development. In
this mode, having a persistent stateful environment that you can have a normal
connection to is exactly what you want. 

This is not recommended for any production role.

```
## WARNING: Do not publish this image. Always build a fresh image.
## The ssh keys are generated on build, so each deployment requires a unique image.
```
