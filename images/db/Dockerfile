FROM debian:stretch
MAINTAINER Alberto Gacías <alberto@migasfree.org>

ENV TERM=xterm \
    DEBIAN_FRONTEND=noninteractive \
    USER=root \
    LANG=en_US.utf8 \
    PG_MAJOR=9.6 \
    PGDATA=/var/lib/postgresql/data

ENV PATH="/usr/lib/postgresql/$PG_MAJOR/bin:$PATH"

# explicitly set user/group IDs
RUN groupadd -r postgres --gid=999 && useradd -r -g postgres --uid=999 postgres && \
    sed --in-place "s/deb.debian.org/softlibre.unizar.es/g" /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends locales ntp cron python postgresql && \
    service ntp start && \
    update-rc.d ntp defaults && \
    # make the "en_US.UTF-8" locale so postgres will be utf-8 enabled by default && \
    localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 && \
    pg_dropcluster $PG_MAJOR main && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /var/run/postgresql && chown -R postgres /var/run/postgresql && \
    mkdir -p /var/lib/postgresql/data && \
    chown postgres /var/lib/postgresql/data && \
    chmod 700 /var/lib/postgresql/data


VOLUME /var/lib/postgresql/data

COPY defaults/usr/bin/backup /usr/bin/backup
COPY defaults/usr/bin/restore /usr/bin/restore
COPY defaults/etc/pam.d/cron /etc/pam.d/cron
COPY defaults/docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 5432
