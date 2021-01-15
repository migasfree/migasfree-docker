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

    # WORKAROUND FOR FEDORA
    chmod -x /usr/lib/rpm/check-files
    
    $_PYTHON_BIN setup.py bdist_rpm

    # WORKAROUND FOR FEDORA    
    chmod +x /usr/lib/rpm/check-files
}

export MIGASFREE_CLIENT_MANAGE_DEVICES='False'
_RESUME="/resume.log"

if [ -z "$_PYTHON_BIN" ] ;
then
    _PYTHON_BIN=$(which python3 || which python2)
fi

echo > $_RESUME
echo $MIGASFREE_CLIENT_PROJECT >> $_RESUME

mkdir -p $_PATH_PKGS/$MIGASFREE_CLIENT_PROJECT

# migasfree-client
# ================
cd /
cp -rf $_PATH_PKGS/migasfree-client .
cd /migasfree-client
build_package
cp -f /migasfree-client/dist/migasfree-client-*.rpm $_PATH_PKGS/$MIGASFREE_CLIENT_PROJECT/
yum -y install /migasfree-client/dist/migasfree-client-*.noarch.rpm
cd -


# migasfree-sdk
# =============
cd /
cp -rf $_PATH_PKGS/migasfree-sdk .
cd /migasfree-sdk
build_package
cp -f /migasfree-sdk/dist/migasfree-sdk-*.rpm $_PATH_PKGS/$MIGASFREE_CLIENT_PROJECT/
yum -y install /migasfree-sdk/dist/migasfree-sdk-*.noarch.rpm
cd -



# migasfree-play
# ============
cd /
cp -r $_PATH_PKGS/migasfree-play .
cd /migasfree-play
cp rpm/migasfree-play.spec /home/userbuild/rpmbuild/SPECS/
mkdir  /home/$_USERBUILD/rpmbuild/SOURCES/migasfree-play-1
cp -r * /home/$_USERBUILD/rpmbuild/SOURCES/migasfree-play-1
cp .env /home/$_USERBUILD/rpmbuild/SOURCES/migasfree-play-1
rm -rf /home/$_USERBUILD/rpmbuild/SOURCES/migasfree-play-1/debian
rm -rf /home/$_USERBUILD/rpmbuild/SOURCES/migasfree-play-1/rpm
pushd /home/$_USERBUILD/rpmbuild/SOURCES
tar -cvzf migasfree-play-1.tar.gz migasfree-play-1
su -c "rpmbuild -ba --define '_topdir /home/$_USERBUILD/rpmbuild'  /home/$_USERBUILD/rpmbuild/SPECS/migasfree-play.spec" $_USERBUILD
cp /home/$_USERBUILD/rpmbuild/RPMS/x86_64/*.rpm /
popd


cd /
# others
# =====
cp /*.rpm $_PATH_PKGS/$MIGASFREE_CLIENT_PROJECT

migasfree -u
migasfree-upload -f /migasfree-client/dist/migasfree-client-*.noarch.rpm
migasfree-upload -f /migasfree-sdk/dist/migasfree-sdk-*.noarch.rpm

for _PKG in /*.rpm
do 
        migasfree-upload -f  $_PKG
done 

cd /

# TOKEN admin
$_PYTHON_BIN -c 'from test import save_token;save_token()'

# Deployment internal
$_PYTHON_BIN -c 'from test import createDeploymentInternalMigasfree;createDeploymentInternalMigasfree()'

# Deployment external
$_PYTHON_BIN -c 'from test import createDeploymenExternalBase;createDeploymenExternalBase()'

migasfree -u
# CHECK migasfree-client PACKAGE
# ==============================
if [ -f /migasfree-client/dist/migasfree-client-*.noarch.rpm ]
then
    echo '    OK    BUILD migasfree-client' >> $_RESUME
else
    echo '    ERROR BUILD migasfree-client' >> $_RESUME
fi


# CHECK migasfree-sdk PACKAGE
# ===========================
if [ -f /migasfree-sdk/dist/migasfree-sdk-*.noarch.rpm ]
then
    echo '    OK    BUILD migasfree-sdk' >> $_RESUME
else
    echo '    ERROR BUILD migasfree-sdk'>> $_RESUME
fi

# CHECK migasfree-play PACKAGE
# ===========================
if [ -f /migasfree-play-*.rpm ]
then
    echo '    OK    BUILD migasfree-play' >> $_RESUME
else
    echo '    ERROR BUILD migasfree-play' >> $_RESUME
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
yum -y remove migasfree-client
yum -y install migasfree-client
migasfree -u
rpm -qa | grep migasfree-client
if [ $? = 0 ]
then
    echo '    OK    internal deployment (install migasfree-client)' >> $_RESUME
else
    echo '    ERROR internal deployment (install migasfree-client)' >> $_RESUME
fi


# CHECK EXTERNAL DEPLOYMENT
# =========================
rm -rf /etc/yum.repos.d/*
migasfree -u
yum -y install nano
rpm -qa | grep nano
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
echo "    $_R" >> $_RESUME

cat $_RESUME | tee -a $_PATH_PKGS/data.log

