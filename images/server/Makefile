#include env_make
NS = migasfree
VERSION ?= 4.9

REPO = server
NAME = mf
INSTANCE = server

PORTS = -p 80:80

VOLUMES = -v /etc/migasfree-server:/etc/migasfree-server \
          -v /repo/repo-migasfree:/repo/repo-migasfree \
          -v /usr/share/migasfree-server:/usr/share/migasfree-server

ENV = -e SERVER_NAME="192.168.92.100"

.PHONY: build push shell run start stop rm release

build:
    docker build -t $(NS)/$(REPO):$(VERSION) .

push:
    docker push $(NS)/$(REPO):$(VERSION)

shell:
    docker run --rm --name $(NAME)-$(INSTANCE) -i -t $(PORTS) $(VOLUMES) $(ENV) $(NS)/$(REPO):$(VERSION) /bin/bash

run:
    docker run --rm --name $(NAME)-$(INSTANCE) $(PORTS) $(VOLUMES) $(ENV) $(NS)/$(REPO):$(VERSION)

start:
    docker run -d --name $(NAME)-$(INSTANCE) $(PORTS) $(VOLUMES) $(ENV) $(NS)/$(REPO):$(VERSION)

stop:
    docker stop $(NAME)-$(INSTANCE)

rm:
    docker rm $(NAME)-$(INSTANCE)

release: build
    make push -e VERSION=$(VERSION)

default: build

