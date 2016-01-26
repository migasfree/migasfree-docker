# Migasfree Server

Provides an isolated web server for [migasfree docker](https://github.com/migasfree/migasfree-docker)


## Build the docker image

```sh
make build
```

## Push the docker image to hub.docker.com

```sh
docker login
make push
```