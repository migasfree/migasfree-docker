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


_SERVER=$(ip route get 8.8.8.8| grep src| sed 's/.*src \(.*\)$/\1/g' | cut -d ' ' -f 1)
if [ "$PWD_HOST_FQDN" = "labs.play-with-docker.com" ]
then
    _SERVER=$(echo "$_SERVER"|tr "." "-")
    _SERVER=ip"$_SERVER"-$SESSION_ID-80.direct.labs.play-with-docker.com
fi

mkdir -p logs

for _CONTAINER in $(cat projects)
do

  _PROJECT=$(echo $_CONTAINER| tr '/' '-')

  _LOG="logs/$_PROJECT.log"
  rm $_LOG > /dev/null || :

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
    -v $_PATH_PKGS:$_PATH_PKGS \
    -v "${PWD}/../test.py:/test.py" \
    --name client-test \
    $_CONTAINER \
    bash -c "

    export MIGASFREE_CLIENT_MANAGE_DEVICES='False'

    _DIST=$(echo $_PROJECT| tr ':' '-')
    mkdir -p $_PATH_PKGS/\$_DIST/

    # Depends
    zypper update -y
    zypper install -y python-setuptools  rpm-build gettext python-requests

    # migasfree-client
    cd /
    cp -r $_PATH_PKGS/migasfree-client .
    cd /migasfree-client/bin
    ./create-package
    cp /migasfree-client/dist/*.rpm $_PATH_PKGS/\$_DIST/
    zypper --no-gpg-checks  install -y /migasfree-client/dist/*.noarch.rpm
    cd -

    # migasfree-sdk
    cp -r $_PATH_PKGS/migasfree-sdk .
    cd migasfree-sdk
    python setup.py bdist_rpm
    cp /migasfree-sdk/dist/*.noarch.rpm $_PATH_PKGS/\$_DIST/
    zypper --no-gpg-checks  install -y /migasfree-sdk/dist/*.noarch.rpm
    cd -


    migasfree -u
    migasfree-upload -f /migasfree-client/dist/*.noarch.rpm


    # TOKEN admin
    python -c 'from test import save_token;save_token()'

    # Deployment internal
    python -c 'from test import createDeploymentInternalMigasfreeClient;createDeploymentInternalMigasfreeClient()'

    # Deployment external
    python -c 'from test import createDeploymenExternalBase;createDeploymenExternalBase()'

    migasfree -u

    echo >> $_PATH_PKGS/data.log
    echo $_PROJECT >> $_PATH_PKGS/data.log


    # CHECK migasfree-client PACKAGE
    # ==============================
    if [ -f /migasfree-client/dist/migasfree-client*.noarch.rpm ]
    then
        echo '    OK    BUILD migasfree-client' >> $_PATH_PKGS/data.log
    else
        echo '    ERROR BUILD migasfree-client' >> $_PATH_PKGS/data.log
    fi

    # CHECK migasfree-sdk PACKAGE
    # ===========================
    if [ -f /migasfree-sdk/dist/migasfree-sdk*.noarch.rpm ]
    then
        echo '    OK    BUILD migasfree-sdk' >> $_PATH_PKGS/data.log
    else
        echo '    ERROR BUILD migasfree-sdk' >> $_PATH_PKGS/data.log
    fi

    # CHECK SYNCHRONIZATION
    # =====================
    _R=\$(python -c 'from test import checkSync;checkSync()')
    echo \"    \$_R\" >> $_PATH_PKGS/data.log



    # CHECK HARDWARE
    # ==============
    _R=\$(python -c 'from test import checkHW;checkHW()')
    echo \"    \$_R\" >> $_PATH_PKGS/data.log


    # CHECK INTERNAL DEPLOYMENT
    # =========================
    zypper remove -y migasfree-client
    zypper install -y migasfree-client
    migasfree -u
    rpm -qa | grep  migasfree-client
    if [ \$? = 0 ]
    then
        echo '    OK    internal deployment (install migasfree-client)' >> $_PATH_PKGS/data.log
    else
        echo '    ERROR internal deployment (install migasfree-client)' >> $_PATH_PKGS/data.log
    fi


    # CHECK EXTERNAL DEPLOYMENT
    # =========================
    rm -rf /etc/zypp/repos.d/*
    zypper clean all
    migasfree -u
    zypper install -y nano


    rpm -qa | grep nano
    if [ \$? = 0 ]
    then
       echo '    OK    external deployment (install nano)' >> $_PATH_PKGS/data.log
    else
       echo '    ERROR external deployment (install nano)' >> $_PATH_PKGS/data.log
    fi


    # CHECK ERRORS NUMBER
    # ===================
    _R=\$(python -c 'from test import checkErrors;checkErrors()')
    echo \"    \$_R\" >> $_PATH_PKGS/data.log


        " | tee -a $_LOG

    docker rm -f client-test > /dev/null

done

cat $_PATH_PKGS/data.log
