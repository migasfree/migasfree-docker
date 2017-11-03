FROM debian:wheezy

RUN apt-get update -y && \
    apt-get install -y wget unzip python-stdeb

COPY docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["/bin/bash", "/docker-entrypoint.sh"]
