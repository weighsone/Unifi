#!/bin/bash
# Easy letsencrypt certs using a bash script.
# v1.3 - 04/04/2016
# By Brielle Bruns <bruns@2mbit.com>
# http://www.sosdg.org

PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

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
#	https://source.sosdg.org/brielle/lets-encrypt-scripts/blob/master/apache-le-alias.conf
#	And:
#	mkdir -p /var/www/letsencrypt-root/.well-known/acme-challenge
#	gen-cert.sh -d domain1.com -d domain2.com -r /var/www/letsencrypt-root
#
# 3) Proxy auth
#	This auth method uses the standalone authenticator with a mod_proxy
# 	https://source.sosdg.org/brielle/lets-encrypt-scripts/blob/master/apache-le-proxy.conf
#	Original proxy idea from:
#	http://evolvedigital.co.uk/how-to-get-letsencrypt-working-with-ispconfig-3/

PROXYAUTH="--standalone --standalone-supported-challenges http-01 --http-01-port 9999"

# Location of LetsEncrypt binary we use
LEBINARY="/usr/src/letsencrypt/letsencrypt-auto"

if [[ ! -x ${LEBINARY} ]]; then
	echo "Error: LetsEncrypt binary not found in ${LEBINARY} !"
	echo "You'll need to do one of the following:"
	echo "1) Change LEBINARY variable in this script"
	echo "2) Install LE manually or via your package manager and do #1"
	echo "3) Use the included get-letsencrypt.sh script to install it"
	exit 1
fi

while getopts "d:r:e:" opt; do
    case $opt in
    d) domains+=("$OPTARG");;
	r) webroot=("$OPTARG");;
	e) email=("$OPTARG");;
    esac
done

MAINDOMAIN=${domains[0]}

if [[ -z ${MAINDOMAIN} ]]; then
	echo "Error: At least one -d argument is required"
	exit 1
fi

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



${LEBINARY} ${email} \
        --server https://acme-v01.api.letsencrypt.org/directory \
        --agree-tos \
        --renew-by-default \
        ${AUTH} \
        ${DOMAINS} \
         certonly
