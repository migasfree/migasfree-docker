#!/bin/bash


function get_distro
{
    local _DISTRO=$($_PYTHON_BIN -c "from migasfree_client import utils; print(utils.get_distro_name())")
    local _MAJOR_VERSION=$($_PYTHON_BIN -c "from migasfree_client import utils; print(utils.get_distro_major_version())")
    local _FILE=${_DISTRO}

    if [ -n "$_MAJOR_VERSION" ]
    then
        _FILE=${_FILE}.${_MAJOR_VERSION}
    fi

    if [ -f "setup.cfg.d/$_FILE" ]
    then
        ln -sf "setup.cfg.d/$_FILE" setup.cfg
        echo "$_FILE"
        return
    fi

    if [ -f "stdeb.cfg.d/$_FILE" ]
    then
        ln -sf "stdeb.cfg.d/$_FILE" stdeb.cfg
        echo "$_FILE"
        return
    fi

    echo ""
}


function build_package {
    get_distro
    if [ "$_PYTHON_BIN" = "/usr/bin/python2" ] ; 
    then
        echo "$_PYTHON_BIN setup.py --command-packages=stdeb.command bdist_deb"
        $_PYTHON_BIN setup.py --command-packages=stdeb.command bdist_deb
    else
        echo "$_PYTHON_BIN setup.py --command-packages=stdeb3.command bdist_deb"
        $_PYTHON_BIN setup.py --command-packages=stdeb3.command bdist_deb
    fi
}


export MIGASFREE_CLIENT_MANAGE_DEVICES='False'

_RESUME="/resume.log"

if [ -z "$_PYTHON_BIN" ] ;
then
    _PYTHON_BIN=$(which python3 || which python2)
fi

echo "_PYTHON_BIN: $_PYTHON_BIN"
echo > $_RESUME
echo $MIGASFREE_CLIENT_PROJECT >> $_RESUME

mkdir -p $_PATH_PKGS/$MIGASFREE_CLIENT_PROJECT

apt-get  update

# migasfree-client
cd /
cp -r $_PATH_PKGS/migasfree-client .
cd /migasfree-client
build_package
#cp /migasfree-client/deb_dist/*.deb $_PATH_PKGS/$MIGASFREE_CLIENT_PROJECT
dpkg -i /migasfree-client/deb_dist/*.deb
apt-get -y install -f
cp /migasfree-client/deb_dist/*.deb /

# migasfree-sdk
cd /
cp -r $_PATH_PKGS/migasfree-sdk .
cd /migasfree-sdk
build_package
#cp /migasfree-sdk/deb_dist/*.deb $_PATH_PKGS/$MIGASFREE_CLIENT_PROJECT
dpkg -i /migasfree-sdk/deb_dist/*.deb
apt-get -y install  -f
cp /migasfree-sdk/deb_dist/*.deb /

# migasfree-play
cd /
cp -r $_PATH_PKGS/migasfree-play .
cd /migasfree-play
/usr/bin/debuild --no-tgz-check -us -uc 


cd /
migasfree -u
migasfree-upload -f /migasfree-client/deb_dist/*.deb
migasfree-upload -f /migasfree-sdk/deb_dist/*.deb


for _PKG in /*.deb
do 
        migasfree-upload -f  $_PKG
done 

# TOKEN admin
$_PYTHON_BIN -c 'from test import save_token;save_token()'

# Deployment internal
$_PYTHON_BIN -c 'from test import createDeploymentInternalMigasfree;createDeploymentInternalMigasfree()'

# Deployment external
$_PYTHON_BIN -c 'from test import createDeploymenExternalBase;createDeploymenExternalBase()'

migasfree -u
# CHECK migasfree-client PACKAGE
# ==============================
if [ -f /migasfree-client/deb_dist/migasfree-client*.deb ]
then
    echo '    OK    BUILD migasfree-client' >> $_RESUME
else
    echo '    ERROR BUILD migasfree-client' >> $_RESUME
fi


# CHECK migasfree-sdk PACKAGE
# ===========================
if [ -f /migasfree-sdk/deb_dist/migasfree-sdk*.deb ]
then
    echo '    OK    BUILD migasfree-sdk'  >> $_RESUME
else
    echo '    ERROR BUILD migasfree-sdk'  >> $_RESUME
fi


# CHECK migasfree-play PACKAGE
# ===========================
if [ -f /migasfree-play*.deb ]
then
    echo '    OK    BUILD migasfree-play'  >> $_RESUME
else
    echo '    ERROR BUILD migasfree-play'  >> $_RESUME
fi


# CHECK SYNCHRONIZATION
# =====================
_R=$($_PYTHON_BIN -c 'from test import checkSync;checkSync()')
echo "    $_R" >> $_RESUME


# CHECK HARDWARE
# ==============
_R=$($_PYTHON_BIN -c 'from test import checkHW;checkHW()')
echo "    $_R" >> $_RESUME


# CHECK INTERNAL DEPLOYMENT
# =========================
apt-get -y purge migasfree-client
apt-get -y install migasfree-client
migasfree -u
dpkg -l | grep migasfree-client
if [ $? = 0 ]
then
    echo '    OK    internal deployment (install migasfree-client)' >> $_RESUME
else
    echo '    ERROR internal deployment (install migasfree-client)' >> $_RESUME
fi


# CHECK EXTERNAL DEPLOYMENT
# =========================
rm -rf /etc/apt/sources.list
apt-get clean
migasfree -u
apt-get -y install nano
dpkg -l | grep nano
if [ $? = 0 ]
then
   echo '    OK    external deployment (install nano)' >> $_RESUME
else
   echo '    ERROR external deployment (install nano)' >> $_RESUME
fi
echo


# CHECK ERRORS NUMBER
# ===================
_R=$($_PYTHON_BIN -c 'from test import checkErrors;checkErrors()')
echo "    $_R"  >> $_RESUME

cat $_RESUME | tee -a $_PATH_PKGS/data.log
