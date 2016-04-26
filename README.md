
# Migasfree Docker

Provides an isolated migasfree server to run in **one host**.


## Requirements

* ***A FQDN for your server***: If you don't have a FQDN you can add a register in /etc/hosts in order to emulate it in a test environment, or you can use the IP server too.

* ***docker engine installed***: https://docs.docker.com/engine/installation/

* ***docker-compose installed***: https://docs.docker.com/compose/install/

* ***haveged installed***: Migasfree server needs a certain entropy in the host to generate gpg keys. If your host is based in Debian run:

```sh
       apt-get install haveged
```

* ***Download docker-compose.yml file***:

```sh
       mkdir mf
       cd mf
       wget https://github.com/migasfree/migasfree-docker/raw/master/mf/docker-compose.yml
```


## Running a migasfree server

First assign the environment variables:

```sh
export FQDN=192.168.92.100
export TZ=Europe/Madrid
export MIGASFREE_PORT=80
export POSTGRES_PORT=5432
export POSTGRES_DB=migasfree
export POSTGRES_USER=migasfree
export POSTGRES_PASSWORD=migasfree
export POSTGRES_ALLOW_HOSTS="192.168.92.0/24"
export POSTGRES_CRON="00 00 * * *"
```

and then, execute  in the **mf directory**:

```sh
docker-compose up -d
```

## Test it!

Open any browser and enter the website, e.g.:

```sh
xdg-open http://192.168.92.100
```


## Configure

Edit the file **/var/lib/migasfree/FQDN/conf/settings.py** and configure the migasfree-server (http://fun-with-migasfree.readthedocs.org/en/master/part05.html#ajustes-del-servidor-migasfree).


## Backup the Database

Migasfree server makes a dump of the database at POSTGRES_CRON config variable, but running this command will force the dump of the database in **/var/lib/migasfree/FQDN/dump/migasfree.sql** :

```sh
docker exec -ti migasfree.mydomain.com-db backup
```


## Restore the DataBase

Copy a dump file in **/var/lib/migasfree/FQDN/dump/migasfree.sql** and run:

```sh
docker exec -ti migasfree.mydomain.com-db restore
```


## Data persistence

In **/var/lib/migasfree/** you will have all data. Make yourself a regular backup of this directory.

