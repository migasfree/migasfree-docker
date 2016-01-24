#!/bin/bash 

function owner {
    _OWNER=$(stat -c %U "$1" 2>/dev/null)
    if [ $? = 1 ] ; then
        mkdir -p "$1"
    fi
    if ! [ "$_OWNER" = "www-data" ] ; then
        echo "CHOWN -R $1"
        chown -R www-data:www-data "$1"
    fi
}


/etc/init.d/haveged start || :


# Waiting to the database
DB_IP=$(env|grep ${FQDN^^}_DB_PORT_5432_TCP_ADDR|awk -F "=" '{print $2}')
while ! exec 6<>/dev/tcp/${DB_IP}/5432; do
    echo "$(date) - waiting connect to the ${DB_IP}:5432"
    sleep 1
done


POSTGRES_HOST=$(python - << EOF
from django.conf import settings
print settings.DATABASES['default']['HOST']
EOF
)

POSTGRES_PORT=$(python - << EOF
from django.conf import settings
print settings.DATABASES['default']['PORT']
EOF
)

POSTGRES_DB=$(python - << EOF
from django.conf import settings
print settings.DATABASES['default']['NAME']
EOF
)

POSTGRES_USER=$(python - << EOF
from django.conf import settings
print settings.DATABASES['default']['USER']
EOF
)

POSTGRES_PASSWORD=$(python - << EOF
from django.conf import settings
print settings.DATABASES['default']['PASSWORD']
EOF
)

_STATIC_ROOT=$(python - << EOF
from django.conf import settings
print settings.STATIC_ROOT
EOF
)

_MIGASFREE_REPO_DIR=$(python - << EOF
from django.conf import settings
print settings.MIGASFREE_REPO_DIR
EOF
)

_MIGASFREE_PROJECT_DIR=$(python - << EOF
from django.conf import settings
print settings.MIGASFREE_PROJECT_DIR
EOF
)

_MIGASFREE_KEYS_DIR=$(python - << EOF
from django.conf import settings
print settings.MIGASFREE_KEYS_DIR
EOF
)

_CHECK_DB=$(python - << EOF
from django.db import connection
try:
    if connection.introspection.table_names():
        print "0"
        exit
except:
    pass
print "1"                 
EOF
)


if [ "$_CHECK_DB" = "1" ] ; then # if DataBase not exists
    # CREATE USER POSTGRESQL
    psql -U postgres -h $POSTGRES_HOST -p $POSTGRES_PORT -c "CREATE USER $POSTGRES_USER WITH CREATEDB NOCREATEUSER ENCRYPTED PASSWORD '$POSTGRES_PASSWORD';" || :
    # CREATE BD POSTGRESQL
    PGPASSWORD=$POSTGRES_PASSWORD createdb -U postgres -h $POSTGRES_HOST -p $POSTGRES_PORT -w -E utf8 -O $POSTGRES_USER $POSTGRES_DB || :

     django-admin.py migrate 

    python - << EOF
import django
django.setup()
from migasfree.server.fixtures import (
    create_registers,
    sequence_reset,
)
create_registers()
sequence_reset()    
EOF


else

    cat <(echo "yes") - | django-admin.py migrate --fake-initial
fi


django-admin.py collectstatic --noinput


# Create neccesary keys 
    python - << EOF
import django
django.setup()
from migasfree.server.security import create_keys_server 
create_keys_server()
EOF


#owner $_MIGASFREE_PROJECT_DIR
owner $_MIGASFREE_KEYS_DIR
#owner $_STATIC_ROOT
owner $_MIGASFREE_REPO_DIR
owner $_MIGASFREE_REPO_DIR/errors

touch /tmp/migasfree.log
owner /tmp/migasfree.log

# Nginx configuration
    python - << EOF
from django.conf import settings

_CONFIG_NGINX = """
server {
    listen 80 ;
    server_name $FQDN ;
    client_max_body_size 500M;

    location /static/ {
        alias %(static_root)s/; 
    }
    
    location /repo/ {
        alias %(repo)s/;
        autoindex on;
    }
    
    location /repo/errors/ {
        deny all;
        return 404;
    }
    
    location / {
        proxy_pass http://localhost:8080/;
        proxy_pass_header Server;
        proxy_set_header Host \$host;
        proxy_redirect off;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Scheme \$scheme;
        proxy_connect_timeout 600;
        proxy_send_timeout 600;
        proxy_read_timeout 600;
    }

}
""" % {'static_root': settings.STATIC_ROOT, 'repo': settings.MIGASFREE_REPO_DIR}
target = open('/etc/nginx/sites-available//migasfree.conf', 'w')
target.write(_CONFIG_NGINX)
target.close()
EOF

ln -s  /etc/nginx/sites-available/migasfree.conf  /etc/nginx/sites-enabled/migasfree.conf || : 

/etc/init.d/nginx restart

circusd /etc/circus/circusd.ini
