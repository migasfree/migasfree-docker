#!/bin/bash
. variables

MIGASFREE_VERSION_DB=0.5
#MIGASFREE_VERSION=master
MIGASFREE_VERSION=4.17.rc1

_SERVER=$(ip route get 8.8.8.8| grep src| sed 's/.*src \(.*\)$/\1/g' | cut -d ' ' -f 1)

if [ "$PWD_HOST_FQDN" = "labs.play-with-docker.com" ]
then
    _SERVER=$(echo "$_SERVER"|tr "." "-")
    _SERVER=ip"$_SERVER"-$SESSION_ID-80.direct.labs.play-with-docker.com
fi

function wait_nginx {
    echo -n "Waiting ngnix ... "
    while true
    do
        STATUS=$(curl --write-out %{http_code} --silent --output /dev/null $_SERVER/accounts/login/) || :
        if [ $STATUS = 200 ]
        then
            break
        fi
        sleep 2
        echo -n "."
    done
}


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


wait_nginx

echo
rm /var/migasfree/dist/data.log || :

pushd /var/migasfree/dist/

if [ -d migasfree-client ]
then
    cd migasfree-client
    git pull
    cd ..
else
    git clone http://github.com/migasfree/migasfree-client.git
fi

if [ -d migasfree-sdk ]
then
    cd migasfree-sdk
    git pull
    cd ..
else
    git clone http://github.com/migasfree/migasfree-sdk.git
fi

popd
cd test-apt
bash test-clients.sh
cd ..


cd test-yum
bash test-clients.sh
cd ..

cd test-zypper
bash test-clients.sh
cd ..


