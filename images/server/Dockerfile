FROM debian:jessie
MAINTAINER Alberto Gacías <alberto@migasfree.org>

# libpq-dev is required by psycopg2 
# libgpgme11-dev is required by gpgme
# rpm createrepo apt-utils bzip2 xz-utils is neccesary to create metadata repositories

ENV _TAG=master \
    TERM=xterm \
    DEBIAN_FRONTEND=noninteractive \
    USER=root \
    LANG=en_US.utf8 \
    DJANGO_SETTINGS_MODULE=migasfree.settings.production \
    _UID=888 \
    _GID=888 \
    _BUILD_DEPENDS='dpkg-dev python-dev libgpgme11-dev python-all debhelper wget unzip g++' \
    _DEPENDS='gnupg rng-tools haveged curl rpm createrepo apt-utils bzip2 xz-utils libpq-dev libzmq-dev libgpgme11 postgresql-client nginx python2.7 python-minimal python-pip' \
    _PIP_DEPENDS='circus==0.12.1 chaussette==1.3.0 pygpgme==0.3' 
     
RUN apt-get update && \
    apt-get install -y --no-install-recommends locales && \ 
    localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8  && \ 
    apt-get install -y --no-install-recommends $_BUILD_DEPENDS  && \
    apt-get install -y --no-install-recommends $_DEPENDS && \
    pip install $_PIP_DEPENDS  && \
    wget https://github.com/migasfree/migasfree/archive/$_TAG.zip && \
    unzip $_TAG.zip && \
    cd migasfree-$_TAG && \
    pip install -r requirements/production.txt &&\
    python setup.py install && \
    rm -rf $_TAG.zip && \
    rm -rf migasfree-$_TAG && \
    update-rc.d haveged defaults && \
    # explicity set user/group IDs to www-data && \
    usermod -u $_UID www-data && \
    groupmod -g $_GID www-data && \
    apt-get -y --auto-remove purge $_BUILD_DEPENDS && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*  

#COPY defaults/etc/migasfree-server/settings.py /etc/migasfree-server/settings.py
COPY defaults/etc/circus/circusd.ini /etc/circus/circusd.ini
COPY defaults/docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["/bin/bash", "/docker-entrypoint.sh"]

EXPOSE 80
