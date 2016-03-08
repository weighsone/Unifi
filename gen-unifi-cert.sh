#!/usr/bin/env bash
# Modified script from here: https://github.com/FarsetLabs/letsencrypt-helper-scripts/blob/master/letsencrypt-unifi.sh
# Modified by: Brielle Bruns <bruns@2mbit.com>
# Download URL: https://source.sosdg.org/brielle/lets-encrypt-scripts
# Last Changed: 2/27/2016
# 02/02/2016: Fixed some errors with key export/import, removed lame docker requirements
# 02/27/2016: More verbose progress report
# 03/08/2016: Add renew option, reformat code, command line options

PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

while getopts "rd:e:" opt; do
    case $opt in
    r) renew="yes";;
    d) domains+=("$OPTARG");;
    e) email=("$OPTARG");;
    esac
done

# Identrust cross-signed CA cert needed by the java keystore for import.
# Can get original here: https://www.identrust.com/certificates/trustid/root-download-x3.html
EXTRACERT="/root/DSTROOTCAX3.txt"

NEWCERT="--renew-by-default certonly"
RENEWCERT="-n renew"

if [[ ! -z ${email} ]]; then
	email="--email ${email}"
else
	email=""
fi

shift $((OPTIND -1))
for val in "${domains[@]}"; do
        DOMAINS="${DOMAINS} -d ${val} "
done


if ( $renew == "yes" ); then
	LEOPTIONS=${RENEWCERT}
else
	LEOPTIONS="${email} ${DOMAINS} ${NEWCERT}"
fi

echo "Firing up standalone authenticator on TCP port 443 and requesting cert..."
/usr/src/letsencrypt/letsencrypt-auto \
	--server https://acme-v01.api.letsencrypt.org/directory \
    --agree-tos \
	--standalone --standalone-supported-challenges tls-sni-01 \
    ${LEOPTIONS}
    

if `md5sum -c /etc/letsencrypt/live/${DOMAIN}/cert.pem.md5 %>/dev/null`; then
	echo "Cert has not changed, not updating controller."
	exit 0
else
	TEMPFILE=$(mktemp)
	echo "Cert has changed, updating controller..."
	md5sum /etc/letsencrypt/live/${DOMAIN}/cert.pem > /etc/letsencrypt/live/${DOMAIN}/cert.pem.md5 
	echo "Using openssl to prepare certificate..."
	openssl pkcs12 -export  -passout pass:aircontrolenterprise \
    	-in /etc/letsencrypt/live/${DOMAIN}/cert.pem \
    	-inkey /etc/letsencrypt/live/${DOMAIN}/privkey.pem \
    	-out ${TEMPFILE} -name unifi \
    	-CAfile /etc/letsencrypt/live/${DOMAIN}/chain.pem -caname root
	echo "Stopping Unifi controller..."
	service unifi stop
	echo "Removing existing certificate from Unifi protected keystore..."
	keytool -delete -alias unifi -keystore /usr/lib/unifi/data/keystore \
		-deststorepass aircontrolenterprise
	echo "Inserting certificate into Unifi keystore..."
	keytool -trustcacerts -importkeystore \
    	-deststorepass aircontrolenterprise \
    	-destkeypass aircontrolenterprise \
    	-destkeystore /usr/lib/unifi/data/keystore \
    	-srckeystore ${TEMPFILE} -srcstoretype PKCS12 \
    	-srcstorepass aircontrolenterprise \
    	-alias unifi
	rm -f ${TEMPFILE}
	echo "Importing cert into Unifi database..."
	java -jar /usr/lib/unifi/lib/ace.jar import_cert \
    	/etc/letsencrypt/live/${DOMAIN}/cert.pem \
    	/etc/letsencrypt/live/${DOMAIN}/chain.pem \
    	${EXTRACERT}
	echo "Starting Unifi controller..."
	service unifi start
	echo "Done!"
fi