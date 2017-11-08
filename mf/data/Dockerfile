FROM debian:jessie

RUN apt-get update -y && \
    apt-get -y install python-requests

COPY data.py /data.py
COPY api.py /api.py

