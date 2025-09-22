# Migasfree Docker

Provides an isolated migasfree server that runs on a **single host**.


## Requirements

- ***A fully-qualified domain name (FQDN) for your server***: If you don't have a FQDN you can add an entry to `/etc/hosts` to emulate one in a test environment, or you can use the server's IP address.

- ***Docker Engine***: [see the official installation guide](https://docs.docker.com/engine/installation/)

- ***Docker Compose***: [installation instructions](https://docs.docker.com/compose/install/)

- ***haveged***: Migasfree server needs sufficient entropy to generate GPG keys. On Debian-based hosts, install it with:

```sh
apt-get install haveged
```


## Installation

1. **Download `docker-compose.yml` and `variables` files**:

   ```sh
   mkdir mf
   cd mf
   wget https://github.com/migasfree/migasfree-docker/raw/master/mf/docker-compose.yml
   wget https://github.com/migasfree/migasfree-docker/raw/master/mf/variables
   ```

2. **Configure the variables**:

   ```sh
   vi variables
   ```


## Running the Stack

```sh
. variables
docker-compose up -d
```


## Test it!

Open a web browser and navigate to the server, e.g.:

```sh
xdg-open http://<FQDN>
```


## Custom Settings

Edit `/var/lib/migasfree/<FQDN>/conf/settings.py` to adjust the [Migasfree server configuration](http://fun-with-migasfree.readthedocs.org/en/master/part05.html#ajustes-del-servidor-migasfree).


## Database Backup

Migasfree server automatically dumps the database according to the `POSTGRES_CRON` configuration variable. To force an immediate dump to `/var/lib/migasfree/<FQDN>/dump/migasfree.sql`, run:

```sh
docker exec -ti migasfree.mydomain.com-db backup
```


## DataBase Restore

Place a dump file at `/var/lib/migasfree/<FQDN>/dump/migasfree.sql` and execute:

```sh
docker exec -ti migasfree.mydomain.com-db restore
```


## Data Persistence

All persistent data is store under `/var/lib/migasfree/`. Make regular backups of this directory to protect your data.
