FROM opensuse:13.2

RUN yum update -y && \
    yum install -y wget unzip rpm-build gettext

COPY docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["/bin/bash", "/docker-entrypoint.sh"]
