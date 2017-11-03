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


docker build -t build-client-debian .
docker run --rm -ti -v $_PATH_PKGS/debian:/migasfree-client-master/deb_dist build-client-debian

if [ "$PWD_HOST_FQDN" = "labs.play-with-docker.com" ]
then
    _IP=$(ip route get 8.8.8.8| grep src| sed 's/.*src \(.*\)$/\1/g' | sed 's/ //g')
    _IP=$(echo "$_IP"|tr "." "-")
    _SERVER=ip"$_IP"-$SESSION_ID-80.direct.labs.play-with-docker.com
else
    _SERVER=localhost
fi


for _PROJECT in $(cat projects)
do
  rm $_PROJECT.log || :
  docker run --rm -ti \
    --mac-address $(mac_project $_PROJECT) \
    -e MIGASFREE_CLIENT_SERVER=$_SERVER \
    -e MIGASFREE_CLIENT_PROJECT=$_PROJECT \
    -e MIGASFREE_PACKAGER_USER=admin \
    -e MIGASFREE_PACKAGER_PASSWORD=admin \
    -e MIGASFREE_PACKAGER_VERSION=$_PROJECT \
    -e MIGASFREE_PACKAGER_STORE=org \
    -e USER=root \
    -v $_PATH_PKGS:$_PATH_PKGS $_PROJECT bash -c "
        apt-get -y update
        apt-get -y upgrade
        dpkg -i  $_PATH_PKGS/debian/*.deb
        apt-get -yf install
        migasfree -u
        migasfree-upload -f $_PATH_PKGS/debian/*.deb
    " | tee -a $_PROJECT.log
done
