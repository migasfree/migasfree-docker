#!/bin/bash


function set_TZ {
    if [ -z "$TZ" ]; then
      TZ="Europe/Madrid"
    fi
    # /etc/timezone for TZ setting
    ln -fs /usr/share/zoneinfo/$TZ /etc/localtime || :
}


function get_migasfree_setting()
{
    echo -n $(DJANGO_SETTINGS_MODULE=migasfree.settings.production python -c "from django.conf import settings; print settings.$1")
}


# owner resource user
function owner()
{
    if [ ! -f "$1" -a ! -d "$1" ]
    then
        mkdir -p "$1"
    fi

    _OWNER=$(stat -c %U "$1" 2>/dev/null)
    if [ "$_OWNER" != "$2" ]
    then
        chown -R $2:$2 "$1"
    fi
}


# Nginx configuration
function create_nginx_config
{
    python - << EOF
from django.conf import settings
_CONFIG_NGINX = """

server {
    listen 80;
    server_name $FQDN $HOST localhost 127.0.0.1;
    client_max_body_size 1024M;


    # STATIC
    # ======
    location /static {
        alias %(static_root)s;
    }


    # SOURCES
    # =======
    #  PACKAGES deb
    location ~* /src/?(.*)deb\$ {
        alias /var/migasfree/repo/\$1deb;
        error_page 404 = @backend;
    }
    #  PACKAGES rpm
    location ~* /src/?(.*)rpm\$ {
        alias /var/migasfree/repo/\$1rpm;
        error_page 404 = @backend;
    }


    # DEPLOYMENTS
    # ===========
    location /public {
        alias %(public)s;
        autoindex on;
    }
    location /public/errors/ {
        deny all;
        return 404;
    }


    # REPO (compatibility)
    # ====================
    location /repo {
        alias %(public)s;
        autoindex on;
    }
    location /repo/errors/ {
        deny all;
        return 404;
    }


    # BACKEND
    # =======
    location / {
        try_files \$uri @backend;
    }
    location @backend {
        add_header 'Access-Control-Allow-Origin' "$http_origin";
        add_header 'Access-Control-Allow-Credentials' 'true';
        add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS';
        add_header 'Access-Control-Allow-Headers' 'Accept,Authorization,Cache-Control,Content-Type,DNT,If-Modified-Since,Keep-Alive,Origin,User-Agent,X-Requested-With';
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host \$http_host;
        proxy_set_header X-Forwarded-Host \$server_name;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header REMOTE_ADDR \$remote_addr;
        proxy_connect_timeout 10;
        proxy_send_timeout 600;
        proxy_read_timeout 600;
    }
}
""" % {'static_root': settings.STATIC_ROOT, 'public': settings.MIGASFREE_PUBLIC_DIR}
target = open('/etc/nginx/sites-available/migasfree.conf', 'w')
target.write(_CONFIG_NGINX)
target.close()
EOF
ln -sf  /etc/nginx/sites-available/migasfree.conf  /etc/nginx/sites-enabled/migasfree.conf
rm /etc/nginx/sites-available/default &> /dev/null || :
}

function set_nginx_server_permissions()
{
    _USER=www-data
    # owner for repositories
    _REPO_PATH=$(get_migasfree_setting MIGASFREE_PUBLIC_DIR)
    owner $_REPO_PATH $_USER
    # owner for keys
    _KEYS_PATH=$(get_migasfree_setting MIGASFREE_KEYS_DIR)
    owner $_KEYS_PATH $_USER
    chmod 700 $_KEYS_PATH
    # owner for migasfree.log
    _TMP_DIR=$(get_migasfree_setting MIGASFREE_TMP_DIR)
    touch "$_TMP_DIR/migasfree.log"
    owner "$_TMP_DIR/migasfree.log" $_USER
}


function run_as_www-data
{
    su - www-data -s /bin/bash -c "$1"
}

function nginx_init
{

    create_nginx_config

    run_as_www-data 'export GPG_TTY=$(tty);DJANGO_SETTINGS_MODULE=migasfree.settings.production python -c "import django; django.setup(); from migasfree.server.secure import create_server_keys; create_server_keys()"'

    /etc/init.d/nginx start

}


function is_db_exists()
{

    _HOST=$(get_migasfree_setting "DATABASES['default']['HOST']")
    _PORT=$(get_migasfree_setting "DATABASES['default']['PORT']")
    _USER=$(get_migasfree_setting "DATABASES['default']['USER']")
    _NAME=$(get_migasfree_setting "DATABASES['default']['NAME']")

    psql -h $_HOST -p $_PORT -U $_USER -tAc "SELECT 1 from pg_database WHERE datname='$_NAME'" 2>/dev/null | grep -q 1
    test $? -eq 0
}


function is_user_exists()
{
    _HOST=$(get_migasfree_setting "DATABASES['default']['HOST']")
    _PORT=$(get_migasfree_setting "DATABASES['default']['PORT']")
    _USER=$(get_migasfree_setting "DATABASES['default']['USER']")
    _CMD="psql postgres -tAc \"SELECT 1 FROM pg_roles WHERE rolname='$_USER';\""
    psql -h $_HOST -p $_PORT -U postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='$_USER';" | grep -q 1
    test $? -eq 0
}


function create_user()
{
    _HOST=$(get_migasfree_setting "DATABASES['default']['HOST']")
    _PORT=$(get_migasfree_setting "DATABASES['default']['PORT']")
    _USER=$(get_migasfree_setting "DATABASES['default']['USER']")
    _PASSWORD=$(get_migasfree_setting "DATABASES['default']['PASSWORD']")
    psql -h $_HOST -p $_PORT -U postgres -tAc "CREATE USER $_USER WITH CREATEDB ENCRYPTED PASSWORD '$_PASSWORD';"
    test $? -eq 0
}

function create_database()
{
    _HOST=$(get_migasfree_setting "DATABASES['default']['HOST']")
    _PORT=$(get_migasfree_setting "DATABASES['default']['PORT']")
    _NAME=$(get_migasfree_setting "DATABASES['default']['NAME']")
    _USER=$(get_migasfree_setting "DATABASES['default']['USER']")
    psql -h $_HOST -p $_PORT -U postgres -tAc "CREATE DATABASE $_NAME WITH OWNER = $_USER ENCODING='UTF8';"
    test $? -eq 0
}


function set_circus_numprocesses() {
    sed -ri "s/^#?(numprocesses\s*=\s*)\S+/\1$(nproc)/" "/etc/circus/circusd.ini"
}


function wait_postgresql {
    while [ -f  /etc/migasfree-server/.init-db ] ; do
      sleep 1
    done
}


function wait_server {
    while [ -f  /etc/migasfree-server/.init-server ] ; do
      sleep 1
    done
    touch /etc/migasfree-server/.init-server
}



function migasfree_init
{

    set_nginx_server_permissions

    wait_postgresql

    wait_server

    is_user_exists || create_user

    is_db_exists && echo yes | cat - | django-admin migrate --fake-initial || (
        create_database
        django-admin migrate
        python - << EOF
import django
django.setup()
from migasfree.server.fixtures import create_initial_data, sequence_reset
create_initial_data()
sequence_reset()
EOF
    )


    nginx_init

    rm /etc/migasfree-server/.init-server

}


function wait_nginx {
    echo "Waiting ngnix ... "
    while true
    do
        STATUS=$(curl --write-out %{http_code} --silent --output /dev/null $FQDN/accounts/login/) || :
        if [ $STATUS = 200 ]
        then
            break
        fi
        sleep 1
    done
}


set_TZ
migasfree_init

echo "Starting circus"
set_circus_numprocesses
circusd --daemon /etc/circus/circusd.ini
circusctl status

echo "One moment..."

if [ "$PORT" = "80" ] || [ "$PORT" = "" ]
then
    _URL=http://$FQDN
else
    _URL=http://$FQDN:$PORT
fi

wait_nginx

echo "
        Container: $HOSTNAME
        Time zome: $TZ  $(date)
        Processes: $(nproc)
               -------O--
              \\         o \\
               \\           \\
                \\           \\
                  -----------
        $_URL is running.
"

while :
do
    sleep 5
done
