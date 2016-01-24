#include env_make
NS = migasfree
VERSION ?= 0.1

REPO = db
NAME = mf
INSTANCE = db

PORTS = -p 5432:5432

VOLUMES = -v /etc/migasfree-server:/etc/migasfree-server \
          -v /var/lib/postgresql/data:/var/lib/postgresql/data \
          -v /var/migasfree/dump:/var/migasfree/dump \

ENV = -e POSTGRES_HOST=`LC_ALL=C ifconfig $$(route|grep default|awk '{print $$8}') | awk '/inet addr/{split($$2,a,":"); print a[2]}'` \
      -e POSTGRES_PORT=`if [ -z $$POSTGRES_PORT ]; then echo 5432; else echo $$POSTGRES_PORT; fi` \
      -e POSTGRES_DB=`if [ -z $$POSTGRES_DB ]; then echo migasfree; else echo $$POSTGRES_DB; fi` \
      -e POSTGRES_USER=`if [ -z $$POSTGRES_USER ]; then echo migasfree; else echo $$POSTGRES_USER; fi` \
      -e POSTGRES_PASSWORD=`if [ -z $$POSTGRES_PASSWORD ]; then echo migasfree; else echo $$POSTGRES_PASSWORD; fi`

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
