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


docker build -t build-client-fedora .
docker run --rm -ti -v $_PATH_PKGS/fedora:/migasfree-client-master/dist build-client-fedora

_SERVER=$(ip route get 8.8.8.8| grep src| sed 's/.*src \(.*\)$/\1/g' | sed 's/ //g')
if [ "$PWD_HOST_FQDN" = "labs.play-with-docker.com" ]
then
    _SERVER=$(echo "$_SERVER"|tr "." "-")
    _SERVER=ip"$_SERVER"-$SESSION_ID-80.direct.labs.play-with-docker.com
fi


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
           yum -y install wget epel-release
           cd /etc/yum.repos.d/
           wget http://pkgrepo.linuxtech.net/el6/release/linuxtech.repo
           yum -y update
           yum -y install $(ls $_PATH_PKGS/fedora/*.noarch.rpm)


           # BUGFIX TODO
           mkdir -p /usr/share/doc/migasfree-client ||:
           echo '4.14' > /usr/share/doc/migasfree-client/VERSION


           migasfree -u

           migasfree-upload -f $(ls $_PATH_PKGS/fedora/*.noarch.rpm)
           " | tee -a $_PROJECT.log
done
