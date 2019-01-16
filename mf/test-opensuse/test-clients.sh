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


docker build -t build-client-opensuse .
docker run --rm -ti -v $_PATH_PKGS/opensuse:/migasfree-client-master/dist build-client-opensuse

_SERVER=$(ip route get 8.8.8.8| grep src| sed 's/.*src \(.*\)$/\1/g' | cut -d ' ' -f 1)
if [ "$PWD_HOST_FQDN" = "labs.play-with-docker.com" ]
then
    _SERVER=$(echo "$_SERVER"|tr "." "-")
    _SERVER=ip"$_SERVER"-$SESSION_ID-80.direct.labs.play-with-docker.com
fi

cp  ../data/* $_PATH_PKGS/opensuse/

for _PROJECT in $(cat projects)
do
    rm $_PROJECT.log || :
    docker run --rm -ti \
        --mac-address $(mac_project $_PROJECT) \
        -e MIGASFREE_CLIENT_SERVER=$_SERVER \
        -e MIGASFREE_CLIENT_PROJECT=$_PROJECT \
        -e MIGASFREE_CLIENT_DEBUG=False \
        -e MIGASFREE_PACKAGER_USER=admin \
        -e MIGASFREE_PACKAGER_PASSWORD=admin \
        -e MIGASFREE_PACKAGER_VERSION=$_PROJECT \
        -e MIGASFREE_PACKAGER_STORE=org \
        -e USER=root \
        -v "$_PATH_PKGS:$_PATH_PKGS" \
        -v "/tmp/migasfree-client:/tmp/migasfree-client" \
        $_PROJECT \
        bash -c "

           zypper update -y
           zypper --no-gpg-checks install -y $(ls $_PATH_PKGS/opensuse/*.noarch.rpm)

           migasfree -u

           migasfree-upload -f $(ls $_PATH_PKGS/opensuse/*.noarch.rpm)


           zypper install -y python-requests

           cd $_PATH_PKGS/opensuse
           python data.py # Create Deployment migasfree-client
           migasfree -u
           zypper remove -y migasfree-client
           zypper install -y migasfree-client
           migasfree -u

           rpm -qa | grep migasfree-client
           if [ \$? = 0 ]
           then
               echo '$_PROJECT OK' >> $_PATH_PKGS/data.log
           else
               echo '$_PROJECT ERROR' >> $_PATH_PKGS/data.log
           fi
           " | tee -a $_PROJECT.log
done

cat $_PATH_PKGS/data.log
