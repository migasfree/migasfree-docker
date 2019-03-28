#!/bin/bash

_MAC_PREFIX="02:42:ac"  # DOCKER
_PATH_PKGS=/var/migasfree/dist

function mac_project {
  _PROJECT="$1"
  _MD5_PROJECT=$(echo $_PROJECT|md5sum| sed -e 's/\(..\)/:\1/g')
  echo "$_MAC_PREFIX:${_MD5_PROJECT:1:8}"
}

function mac_random {
  echo "$_MAC_PREFIX$( for i in {1..6} ; do echo -n ${hexchars:$(( $RANDOM % 16 )):1} ; done | sed -e 's/\(..\)/:\1/g' )" # RANDOM MAC
}


cd ../data
docker build -t api-migasfree .
cd -


_SERVER=$(ip route get 8.8.8.8| grep src| sed 's/.*src \(.*\)$/\1/g' | cut -d ' ' -f 1)
if [ "$PWD_HOST_FQDN" = "labs.play-with-docker.com" ]
then
    _SERVER=$(echo "$_SERVER"|tr "." "-")
    _SERVER=ip"$_SERVER"-$SESSION_ID-80.direct.labs.play-with-docker.com
fi

mkdir -p logs

for _PROJECT in $(cat projects)
do
  
  _LOG="logs/$_PROJECT.log"
  rm $_LOG > /dev/null || :

  _DIST=$(echo $_PROJECT| tr ':' '-')

  # PACKAGE BUILD (migasfree-client)
  docker build -t build-client-$_PROJECT  -f Dockerfile/$_PROJECT .
  docker run --rm -ti -v $_PATH_PKGS/$_DIST:/dist build-client-$_PROJECT


  docker run -ti \
    --mac-address $(mac_project $_PROJECT) \
    -e MIGASFREE_CLIENT_SERVER=$_SERVER \
    -e MIGASFREE_CLIENT_PROJECT=$_PROJECT \
    -e MIGASFREE_CLIENT_DEBUG=False \
    -e MIGASFREE_PACKAGER_USER=admin \
    -e MIGASFREE_PACKAGER_PASSWORD=admin \
    -e MIGASFREE_PACKAGER_VERSION=$_PROJECT \
    -e MIGASFREE_PACKAGER_STORE=org \
    -e USER=root \
    -v $_PATH_PKGS/$_DIST:/dist \
    -v "/tmp/migasfree-client:/tmp/migasfree-client" \
    --name client-test \
    $_PROJECT \
    bash -c "
        cd dist
        apt-get -y update
        dpkg -i  *.deb
        apt-get -y install -f

        migasfree -u
        migasfree-upload -f /dist/*.deb

    " | tee -a $_LOG


  docker commit client-test client-test-img

  docker run -ti --rm \
    -e MIGASFREE_CLIENT_SERVER=$_SERVER \
    -e MIGASFREE_CLIENT_PROJECT=$_PROJECT \
    api-migasfree bash -c "
        cd /
        /usr/bin/python data.py
    " | tee -a $_LOG


  docker run -ti --rm \
    --mac-address $(mac_project $_PROJECT) \
    -v $_PATH_PKGS:$_PATH_PKGS \
    -v "/tmp/migasfree-client:/tmp/migasfree-client" \
    client-test-img \
    bash -c "
        migasfree -u
        apt-get -y purge migasfree-client
        apt-get -y install migasfree-client
        migasfree -u

       dpkg -l | grep migasfree-client
       if [ \$? = 0 ]
       then
           echo 'OK    $_PROJECT internal deployment (install migasfree-client)' >> $_PATH_PKGS/data.log
       else
           echo 'ERROR $_PROJECT internal deployment (install migasfree-client)' >> $_PATH_PKGS/data.log
       fi
    " | tee -a $_LOG


  docker run -ti --rm \
    --mac-address $(mac_project $_PROJECT) \
    -v $_PATH_PKGS:$_PATH_PKGS \
    -v "/tmp/migasfree-client:/tmp/migasfree-client" \
    client-test-img \
    bash -c "
        rm -rf /etc/apt/sources.list
        apt-get clean
        migasfree -u
        apt-get install nano

        cat /etc/apt/sources.list.d/migasfree.list

       dpkg -l | grep nano
       if [ \$? = 0 ]
       then
           echo 'OK    $_PROJECT external deployment (install nano)' >> $_PATH_PKGS/data.log
       else
           echo 'ERROR $_PROJECT external deployment (install nano)' >> $_PATH_PKGS/data.log
       fi
       echo
    " | tee -a $_LOG


    docker rmi -f client-test-img
    docker rm -f client-test

done

cat $_PATH_PKGS/data.log
