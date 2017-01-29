#!/bin/bash
set -e


function save_environment {
    _ENV_FILE=/etc/environment
    echo "#!/bin/bash" > $_ENV_FILE
    vars=$(printenv|awk -F '=' '{print $1}')
    for var in $vars
    do
        echo  "export $var='$(printenv $var)'" >> $_ENV_FILE
    done
}

function set_TZ {
    if [ -z "$TZ" ]; then
      TZ="Europe/Madrid"
    fi
    # /etc/timezone for TZ setting
    ln -fs /usr/share/zoneinfo/$TZ /etc/localtime || :
}

function cron_init
{
    if [ -z "$POSTGRES_CRON" ]; then
        POSTGRES_CRON="0 0 * * *"
    fi
    CRON=$(echo "$POSTGRES_CRON" |tr -d "'") # remove single quote
    echo "$CRON /usr/bin/backup" > /tmp/cron
    crontab /tmp/cron
    rm /tmp/cron
    service cron start
}


function get_pg_major_version()
{
    echo -n $(psql --version | head -1 | cut -d ' ' -f 3 | cut -d '.' -f1,2)
}


function set_listen_addresses() {
    sedEscapedValue="$(echo "$1" | sed 's/[\/&]/\\&/g')"
    sed -ri "s/^#?(listen_addresses\s*=\s*)\S+/\1'$sedEscapedValue'/" $(get_pg_config)
}


function is_pg_cluster_exists()
{
    pg_lsclusters | grep $PGDATA
    test $? -eq 0
}


function pg__data_init
{
    # Create postgres data directory and run initdb if needed

     is_pg_cluster_exists || (
        echo "Initializing database files in $PGDATA"
        chown postgres:postgres $PGDATA

        pg_createcluster --locale en_US.UTF-8 --start $(get_pg_major_version) main -d $PGDATA

        # mv configuration to $PGDATA directory
        cp /etc/postgresql/$(get_pg_major_version)/main/postgresql.conf $PGDATA/postgresql.conf
        cp /etc/postgresql/$(get_pg_major_version)/main/pg_hba.conf $PGDATA/pg_hba.conf
        cp /etc/postgresql/$(get_pg_major_version)/main/pg_ident.conf $PGDATA/pg_ident.conf

      )

}

function is_pg_user_exists()
{
    _CMD="psql postgres -tAc \"SELECT 1 FROM pg_roles WHERE rolname='$POSTGRES_USER';\""
    su postgres -l -c "$_CMD" | grep -q 1
    test $? -eq 0
}

function pg_create_user()
{
    _CMD="psql postgres -tAc \"CREATE USER $POSTGRES_USER WITH CREATEDB ENCRYPTED PASSWORD '$POSTGRESS_PASSWORD';\""
    su postgres -l -c "$_CMD"
    test $? -eq 0
}

function get_pg_hba()
{
    #echo -n $(su - postgres -c "psql -t -P format=unaligned -c 'show hba_file';")
    echo -n /etc/postgresql/$(get_pg_major_version)/main/pg_hba.conf
}

function get_pg_config()
{
    #echo -n $(su - postgres -c "psql -t -P format=unaligned -c 'show config_file';")
    echo -n /etc/postgresql/$(get_pg_major_version)/main/postgresql.conf
}

function is_pg_hba_configured()
{
    grep -q $POSTGRES_DB $(get_pg_hba)
    test $? -eq 0
}

function get_iface_gateway()
{
    echo -n $(ip route show|grep default|awk '{print $5}')
}

function get_default_ip()
{
    echo -n $( ip addr list $(get_iface_gateway) |grep "inet " |cut -d' ' -f6|cut -d/ -f1)
}

function get_default_network()
{
    echo -n $(ip route show|grep $(get_default_ip) |awk '{print $1}')
}

function set_pg_config()
{

    _CON_FILE=$(get_pg_hba)
    _CAD="# Put your actual configuration here"
    sed -i "s/$_CAD/$_CAD\\nlocal   $POSTGRES_DB             $POSTGRES_USER                     password\\n/g" $_CON_FILE


    for _ELEMENT in $POSTGRES_ALLOW_HOSTS
    do
        echo "host all all $_ELEMENT trust" >> $_CON_FILE
    done

    echo "host all all $(get_default_network) trust" >> $_CON_FILE
    echo "host all all 127.0.0.1/8 trust" >> $_CON_FILE

    set_listen_addresses "*"

}


function db_server_init()
{
    export DJANGO_SETTINGS_MODULE=migasfree.settings.production

#    service postgresql start

#    is_pg_user_exists || pg_create_user

#    is_pg_hba_configured || (
#        set_pg_config
#        service postgresql restart || :
#    )

    set_pg_config
    service postgresql restart
    is_pg_user_exists || pg_create_user


}


touch /etc/migasfree-server/.init-db

if ! [ -f /etc/migasfree-server/settings.py ] ; then
    cat <<EOF>> /etc/migasfree-server/settings.py
DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.postgresql_psycopg2',
            'NAME': '$POSTGRES_DB',
            'USER': '$POSTGRES_USER',
            'PASSWORD': '$POSTGRES_PASSWORD',
            'HOST': '$POSTGRES_HOST',
            'PORT': '$POSTGRES_PORT',
        }
    }
EOF
fi


cd /etc/migasfree-server
POSTGRES_HOST=$(python -c "import settings;print settings.DATABASES['default']['HOST']")
POSTGRES_PORT=$(python -c "import settings;print settings.DATABASES['default']['PORT']")
POSTGRES_DB=$(python -c "import settings;print settings.DATABASES['default']['NAME']")
POSTGRES_USER=$(python -c "import settings;print settings.DATABASES['default']['USER']")
POSTGRES_PASSWORD=$(python -c "import settings;print settings.DATABASES['default']['PASSWORD']")


save_environment
set_TZ
cron_init
pg__data_init
db_server_init

rm /etc/migasfree-server/.init-db
while :
do
    sleep 5
done
