#!/bin/bash
# Easy letsencrypt certs using a bash script.
# v1.2 - 12/13/2015
# By Brielle Bruns <bruns@2mbit.com>
# http://www.sosdg.org


# Use like:  gen-cert.sh -d domain1.com -d domain2.com
#
# There are three options for authentication:
#
# 1) Webroot (normal)
#	Specify -r flag with -d and -e flags.
#	gen-cert.sh -d domain1.com -r /var/www/domain1.com
#
# 2) Webroot (alias)
#	Same as #1, but also include an alias directive in apache like in:
#	http://users.sosdg.org/~bruns/lets-encrypt/apache-le-alias.conf
#	And:
#	mkdir -p /var/www/letsencrypt-root/.well-known/acme-challenge
#	gen-cert.sh -d domain1.com -d domain2.com -r /var/www/letsencrypt-root/.well-known/acme-challenge
#
# 3) Proxy auth
#	This auth method uses the standalone authenticator with a mod_proxy
# 	http://users.sosdg.org/~bruns/lets-encrypt/apache-le-proxy.conf
#	Original proxy idea from:
#	http://evolvedigital.co.uk/how-to-get-letsencrypt-working-with-ispconfig-3/

PROXYAUTH="--standalone --standalone-supported-challenges http-01 --http-01-port 9999"

while getopts "d:r:e:" opt; do
    case $opt in
        d) domains+=("$OPTARG");;
	r) webroot=("$OPTARG");;
	e) email=("$OPTARG");;
    esac
done

if [[ ! -z ${email} ]]; then
	email="--email ${email}"
else
	email=""
fi

# Webroot auth method, activated with -r
WEBAUTH="-a webroot --webroot-path ${webroot}"

if [[ -z ${webroot} ]]; then
	AUTH=${PROXYAUTH}
else
	AUTH=${WEBAUTH}
fi

shift $((OPTIND -1))
for val in "${domains[@]}"; do
        DOMAINS="${DOMAINS} -d ${val} "
done



cd /usr/src/letsencrypt
./letsencrypt-auto ${email} \
        --server https://acme-v01.api.letsencrypt.org/directory \
        --agree-tos \
        --renew-by-default \
        ${AUTH} \
        ${DOMAINS} \
         certonly
