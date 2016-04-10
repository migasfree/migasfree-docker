#include env_make

USER = migasfree
REPO = server
VERSION ?= 4.10-devel


.PHONY: build push release


build:
	docker build -t $(USER)/$(REPO):$(VERSION) .

push:
	docker push $(USER)/$(REPO):$(VERSION)

release: build
	make push -e VERSION=$(VERSION)

default: build
