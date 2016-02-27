#!/usr/bin/env bash
# Modified script from here: https://github.com/FarsetLabs/letsencrypt-helper-scripts/blob/master/letsencrypt-unifi.sh
# Modified by: Brielle Bruns <bruns@2mbit.com>
# Download URL: https://source.sosdg.org/brielle/lets-encrypt-scripts
# Last Changed: 2/27/2016
# 02/02/2016: Fixed some errors with key export/import, removed lame docker requirements
# 02/27/2016: More verbose progress report

# The main domain name of your controller
DOMAIN="unifi.xxxx.xxxxx"

# Your e-mail address for notifications of certificate issues
EMAIL="email@here"

# Identrust cross-signed CA cert needed by the java keystore for import.
# Can get original here: https://www.identrust.com/certificates/trustid/root-download-x3.html
EXTRACERT="/root/DSTROOTCAX3.txt"

TEMPFILE=$(mktemp)

echo "Stopping Unifi controller..."
service unifi stop
echo "Firing up standalone authenticator on TCP port 443 and requesting cert..."
/usr/src/letsencrypt/letsencrypt-auto \
	--email ${EMAIL} \
	--server https://acme-v01.api.letsencrypt.org/directory \
        --agree-tos \
        --renew-by-default \
        -d ${DOMAIN} \
	--standalone --standalone-supported-challenges tls-sni-01 \
         certonly
echo "Using openssl to prepare certificate..."
openssl pkcs12 -export  -passout pass:aircontrolenterprise \
    -in /etc/letsencrypt/live/${DOMAIN}/cert.pem \
    -inkey /etc/letsencrypt/live/${DOMAIN}/privkey.pem \
    -out ${TEMPFILE} -name unifi \
    -CAfile /etc/letsencrypt/live/${DOMAIN}/chain.pem -caname root
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