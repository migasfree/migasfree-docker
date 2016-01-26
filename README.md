
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

In the **mf directory** run:

```sh
FQDN=migasfree.mydomain.com docker-compose up -d
```

***overwrite 'migasfree.mydomain.com' with your FQDN or IP server***


## Test it!

Open any browser and enter the website, e.g.:

```sh
xdg-open http://migasfree.mydomain.com
```


## Configure

Edit the file **/var/lib/migasfree/FQDN/conf/settings.py** and configure the migasfree-server (http://fun-with-migasfree.readthedocs.org/en/master/part05.html#ajustes-del-servidor-migasfree).


## Backup the Database

Migasfree server makes a dump of the database every day at 00:00 UTC. Running this command will force the dump of the database in **/var/lib/migasfree/FQDN/dump/migasfree.sql** :

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

