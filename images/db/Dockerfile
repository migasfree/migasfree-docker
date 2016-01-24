FROM debian:jessie
MAINTAINER Alberto Gacías <alberto@migasfree.org>

ENV TERM=xterm \ 
    DEBIAN_FRONTEND=noninteractive \
    USER=root \
    LANG=en_US.utf8 \ 
    PG_MAJOR=9.5 \
    PG_VERSION=9.5.0-1.pgdg80+2 \
    PGDATA=/var/lib/postgresql/data

ENV PATH="/usr/lib/postgresql/$PG_MAJOR/bin:$PATH"

# explicitly set user/group IDs
RUN groupadd -r postgres --gid=999 && useradd -r -g postgres --uid=999 postgres && \
    # grab gosu for easy step-down from root && \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 && \
    apt-get update && \
    apt-get install -y --no-install-recommends cron python && \
    apt-get install -y --no-install-recommends ca-certificates wget && \
    wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/1.2/gosu-$(dpkg --print-architecture)" && \
    wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/1.2/gosu-$(dpkg --print-architecture).asc" && \
    gpg --verify /usr/local/bin/gosu.asc && \
    rm /usr/local/bin/gosu.asc && \
    chmod +x /usr/local/bin/gosu && \
    apt-get purge -y --auto-remove ca-certificates wget && \
    # make the "en_US.UTF-8" locale so postgres will be utf-8 enabled by default && \
    apt-get update && \
    apt-get install -y --no-install-recommends locales && rm -rf /var/lib/apt/lists/* && \
    localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 && \
    mkdir /docker-entrypoint-initdb.d && \
    apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8 && \
    echo 'deb http://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main' $PG_MAJOR > /etc/apt/sources.list.d/pgdg.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends postgresql-common && \
    sed -ri 's/#(create_main_cluster) .*$/\1 = false/' /etc/postgresql-common/createcluster.conf && \
    apt-get install -y --no-install-recommends postgresql-$PG_MAJOR=$PG_VERSION postgresql-contrib-$PG_MAJOR=$PG_VERSION && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /var/run/postgresql && chown -R postgres /var/run/postgresql 

VOLUME /var/lib/postgresql/data

COPY defaults/usr/bin/backup /usr/bin/backup 
COPY defaults/usr/bin/restore /usr/bin/restore
COPY defaults/etc/pam.d/cron /etc/pam.d/cron
COPY defaults/docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 5432

CMD ["postgres"]
