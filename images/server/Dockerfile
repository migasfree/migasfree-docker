FROM debian:buster-slim
MAINTAINER Alberto Gacías <alberto@migasfree.org>

COPY VERSION /VERSION

ENV TERM=xterm \
    DEBIAN_FRONTEND=noninteractive \
    USER=root \
    LANG=en_US.UTF-8 \
    DJANGO_SETTINGS_MODULE=migasfree.settings.production \
    _UID=890 \
    _GID=890 \
    _BUILD_DEPENDS='git python3-dev libgpgme11-dev python3-all python3-all-dev debhelper unzip g++ gcc-8 libcairo2-dev libjpeg62-turbo-dev libxml2-dev libxslt1-dev libpq-dev' \
    _DEPENDS='libzmq5 dpkg-dev gnupg rng-tools curl rpm createrepo apt-utils bzip2 xz-utils libgpgme11 postgresql-client nginx python3 python3-minimal python3-pip p7zip-full vim wget netcat-openbsd logrotate' \
    _PIP_DEPENDS='gunicorn==20.0.4'

RUN _TAG=$(cat /VERSION) && \
    #sed --in-place "s/deb.debian.org/softlibre.unizar.es/g" /etc/apt/sources.list && \
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
    python3 -m pip install --upgrade pip && \
    python3 -m pip install --upgrade setuptools wheel && \
    pip install $_PIP_DEPENDS  && \
    cd / && \
    git clone https://github.com/django-admin-bootstrapped/django-admin-bootstrapped.git && \
    cd django-admin-bootstrapped && \
    git checkout 2.5.7 &&\
    sed --in-place "s/        'Django>=1.8,<1.9',/        'Django>=1.8',/g" setup.py && \
    python3 setup.py install && \
    cd / && \
    wget https://github.com/migasfree/migasfree/archive/$_TAG.zip && \
    unzip $_TAG.zip && \
    cd migasfree-$_TAG && \
    pip install  -r  requirements/production.txt &&\
    python3 setup.py install && \
    rm -rf /$_TAG.zip && \
    rm -rf /migasfree-$_TAG && \
    rm -rf /root/.cache && \
    # explicity set user/group IDs to www-data && \
    usermod -u $_UID www-data && \
    groupmod -g $_GID www-data && \
    django-admin collectstatic --noinput && \
    apt-get -y --auto-remove purge $_BUILD_DEPENDS && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/pip_build_root && \
    rm -rf /root/.cache

COPY defaults/etc/logrotate.d/nginx /etc/logrotate.d/nginx

COPY defaults/docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["/bin/bash", "/docker-entrypoint.sh"]

EXPOSE 80
