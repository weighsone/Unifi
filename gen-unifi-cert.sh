#!/usr/bin/env bash
# Modified script from here: https://github.com/FarsetLabs/letsencrypt-helper-scripts/blob/master/letsencrypt-unifi.sh
# Modified by: Brielle Bruns <bruns@2mbit.com>
# Last Changed: 2/2/2016
# Changed: Fixed some errors with key export/import, removed lame
# docker requirements
DOMAIN="unifi.xxxx.xxxxx"
EMAIL="email@here"
EXTRACERT="/root/DSTROOTCAX3.txt"
TEMPFILE=$(mktemp)
service unifi stop
/usr/src/letsencrypt/letsencrypt-auto \
	--email ${EMAIL} \
	--server https://acme-v01.api.letsencrypt.org/directory \
        --agree-tos \
        --renew-by-default \
        -d ${DOMAIN} \
	--standalone --standalone-supported-challenges tls-sni-01 \
         certonly
openssl pkcs12 -export  -passout pass:aircontrolenterprise \
    -in /etc/letsencrypt/live/${DOMAIN}/cert.pem \
    -inkey /etc/letsencrypt/live/${DOMAIN}/privkey.pem \
    -out ${TEMPFILE} -name unifi \
    -CAfile /etc/letsencrypt/live/${DOMAIN}/chain.pem -caname root
keytool -delete -alias unifi -keystore /usr/lib/unifi/data/keystore \
	-deststorepass aircontrolenterprise
keytool -trustcacerts -importkeystore \
    -deststorepass aircontrolenterprise \
    -destkeypass aircontrolenterprise \
    -destkeystore /usr/lib/unifi/data/keystore \
    -srckeystore ${TEMPFILE} -srcstoretype PKCS12 \
    -srcstorepass aircontrolenterprise \
    -alias unifi
rm -f ${TEMPFILE}
java -jar /usr/lib/unifi/lib/ace.jar import_cert \
    /etc/letsencrypt/live/${DOMAIN}/cert.pem \
    /etc/letsencrypt/live/${DOMAIN}/chain.pem \
    ${EXTRACERT}
service unifi start
