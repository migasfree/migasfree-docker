#!/bin/bash
. variables
MIGASFREE_VERSION_DB=0.4
MIGASFREE_VERSION=master

# POSTGRES
docker inspect --type=image migasfree/db:$MIGASFREE_VERSION_DB >/dev/null
if [ $? = 1 ] # is not local image migasfree/db
then
    docker pull migasfree/db:$MIGASFREE_VERSION_DB >/dev/null
    if [ $? = 1 ] # is not exists image migasfree/db
    then
        cd ../images/db/
        make build
        cd ../../mf
    fi
fi

# MIGASFREE SERVER
docker rm -f  $FQDN-server $FQDN-db
docker rmi -f migasfree/server:master
rm -rf /var/lib/migasfree/$FQDN/
cd ../images/server/
make build
cd ../../mf
docker-compose up -d
docker logs -f $FQDN-server
