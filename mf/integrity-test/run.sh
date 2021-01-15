#!/bin/bash

. ../variables

_PATH_PKGS="/var/migasfree/dist"
_MAC_PREFIX="02:42:ac"  # DOCKER

function mac_project {
  _PROJECT="$1"
  _MD5_PROJECT=$(echo $_PROJECT|md5sum| sed -e 's/\(..\)/:\1/g')
  echo "$_MAC_PREFIX:${_MD5_PROJECT:1:8}"
}


function mac_random {
  echo "$_MAC_PREFIX$( for i in {1..6} ; do echo -n ${hexchars:$(( $RANDOM % 16 )):1} ; done | sed -e 's/\(..\)/:\1/g' )" # RANDOM MAC
}


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


function testing {
    local _PMS="$1"
    local _PROJECTS="$2"

    pushd $_PMS

    if [ -z $_PROJECTS ];
    then
        _PROJECTS=$(ls *.*)
    fi

    for _PROJECT in $_PROJECTS
    do

      docker build -t testing:$_PROJECT -f $_PROJECT .

      mkdir -p "logs"
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
        -e _PATH_PKGS=$_PATH_PKGS \
        -e USER=root \
        -v $_PATH_PKGS:$_PATH_PKGS \
        -v "${PWD}/../test.py:/test.py" \
        --name client-test \
        testing:$_PROJECT  | tee -a $_LOG



        docker rm -f client-test > /dev/null

    done
    popd
}



_SERVER=$(ip route get 8.8.8.8| grep src| sed 's/.*src \(.*\)$/\1/g' | cut -d ' ' -f 1)
if [ "$PWD_HOST_FQDN" = "labs.play-with-docker.com" ]
then
    _SERVER=$(echo "$_SERVER"|tr "." "-")
    _SERVER=ip"$_SERVER"-$SESSION_ID-80.direct.labs.play-with-docker.com
fi

mkdir -p logs
rm $_PATH_PKGS/data.log

cd ..

# POSTGRES
# =========
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
# ================
docker rm -f  $FQDN-server $FQDN-db
#docker rmi -f migasfree/server:$MIGASFREE_VERSION
rm -rf /var/lib/migasfree/$FQDN/
cd ../images/server/
make build
cd ../../mf
docker-compose up -d
wait_nginx
echo 'DEBUG=True' >> /var/lib/migasfree/$FQDN/conf/settings.py
docker restart $FQDN-server
wait_nginx
echo
echo > $_PATH_PKGS/data.log

# COPY KEYS
# =========
mkdir -p /var/lib/migasfree/$FQDN/keys/keys
cp -rpf keys/.gnupg /var/lib/migasfree/$FQDN/keys/keys/

pushd $_PATH_PKGS

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

if [ -d migasfree-play ]
then
    cd migasfree-play
    git pull
    cd ..
else
    git clone http://github.com/migasfree/migasfree-play.git
fi

popd

cd integrity-test

if true ;
then
    testing "apt"
    testing "yum"
    testing "zypper"
else 
    testing "apt" "ubuntu.20"
fi

# Copiamos scripts
cp install-client $_PATH_PKGS/$_SERVER/public/
cp install-play $_PATH_PKGS/$_SERVER/public/
cp install-sdk $_PATH_PKGS/$_SERVER/public/

# Descargamos los repositorios desde el server
cd $_PATH_PKGS
wget -r --level=0 --no-parent --reject="index.html*" --exclude-directories=*/*/EXTERNAL,*/*/STORES  http://$_SERVER/public/

# Descargamos la key publica de los repositorios
wget http://$_SERVER/get_key_repositories -O $_SERVER/public/gpg_key

cd -

echo
echo "==================   RESUME   ================="
cat $_PATH_PKGS/data.log

echo "REPOSITORIES stored in $_PATH_PKGS/$_SERVER/public"
echo
echo
