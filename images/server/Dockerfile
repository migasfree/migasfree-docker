FROM debian:jessie
MAINTAINER Alberto Gacías <alberto@migasfree.org>

COPY VERSION /VERSION

ENV TERM=xterm \
    DEBIAN_FRONTEND=noninteractive \
    USER=root \
    LANG=en_US.UTF-8 \
    DJANGO_SETTINGS_MODULE=migasfree.settings.production \
    _UID=890 \
    _GID=890 \
    _BUILD_DEPENDS='python-dev libgpgme11-dev python-all python-all-dev debhelper unzip g++ libcairo2-dev libjpeg62-turbo-dev libxml2-dev libxslt1-dev' \
    _DEPENDS='dpkg-dev gnupg rng-tools curl rpm createrepo apt-utils bzip2 xz-utils libpq-dev libzmq-dev libgpgme11 postgresql-client nginx python2.7 python-minimal python-pip p7zip-full vim wget netcat-openbsd' \
    _PIP_DEPENDS='circus==0.13.0 chaussette==1.3.0  meinheld==0.5.9 pygpgme==0.3'

RUN _TAG=$(cat /VERSION) && \
    sed --in-place "s/httpredir.debian.org/softlibre.unizar.es/g" /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends apt-utils && \
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
    apt-get install -y locales && \
    dpkg-reconfigure locales && \
    update-locale LANG=$LANG && \
    apt-get install -y --no-install-recommends ntp coreutils && \
    service ntp start && \
    update-rc.d ntp defaults && \
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
    # explicity set user/group IDs to www-data && \
    usermod -u $_UID www-data && \
    groupmod -g $_GID www-data && \
    django-admin collectstatic --noinput && \
    apt-get -y --auto-remove purge $_BUILD_DEPENDS && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY defaults/etc/circus/circusd.ini /etc/circus/circusd.ini

COPY defaults/docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["/bin/bash", "/docker-entrypoint.sh"]

EXPOSE 80

