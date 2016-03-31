#!/bin/bash

# Type of auth method you want to use - overrides any stored auth methods
# in the account.  If you don't want to override them, set
# AUTHMETHOD=""
AUTHMETHOD="-a webroot --webroot-path /var/www/letsencrypt-root/"

/usr/src/letsencrypt/letsencrypt-auto \
        --server https://acme-v01.api.letsencrypt.org/directory \
        --agree-tos \
        ${AUTHMETHOD} \
        -n \
        renew
 
 # Put other commands you need to run below here
 # like restarting apache, copying cert files, etc.
/etc/init.d/apache2 restart &>/dev/null
