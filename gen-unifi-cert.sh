#!/usr/bin/env bash
# Modified script from here: https://github.com/FarsetLabs/letsencrypt-helper-scripts/blob/master/letsencrypt-unifi.sh
# Modified by: Brielle Bruns <bruns@2mbit.com>
# Download URL: https://source.sosdg.org/brielle/lets-encrypt-scripts
# Version: 1.2
# Last Changed: 03/24/2016
# 02/02/2016: Fixed some errors with key export/import, removed lame docker requirements
# 02/27/2016: More verbose progress report
# 03/08/2016: Add renew option, reformat code, command line options
# 03/24/2016: More sanity checking, embedding cert

PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

while getopts "ird:e:" opt; do
    case $opt in
    i) onlyinsert="yes";;
    r) renew="yes";;
    d) domains+=("$OPTARG");;
    e) email=("$OPTARG");;
    esac
done

# Location of LetsEncrypt binary we use
LEBINARY="/usr/src/letsencrypt/letsencrypt-auto"

# Command line options depending on New or Renew.
NEWCERT="--renew-by-default certonly"
RENEWCERT="-n renew"

if [[ ! -x ${LEBINARY} ]]; then
	echo "Error: LetsEncrypt binary not found in ${LEBINARY} !"
	echo "You'll need to do one of the following:"
	echo "1) Change LEBINARY variable in this script"
	echo "2) Install LE manually or via your package manager and do #1"
	echo "3) Use the included get-letsencrypt.sh script to install it"
	exit 1
fi


if [[ ! -z ${email} ]]; then
	email="--email ${email}"
else
	email=""
fi

shift $((OPTIND -1))
for val in "${domains[@]}"; do
        DOMAINS="${DOMAINS} -d ${val} "
done

MAINDOMAIN=${domains[0]}

if [[ -z ${MAINDOMAIN} ]]; then
	echo "Error: At least one -d argument is required"
	exit 1
fi

if [[ ${renew} == "yes" ]]; then
	LEOPTIONS=${RENEWCERT}
else
	LEOPTIONS="${email} ${DOMAINS} ${NEWCERT}"
fi

if [[ ${onlyinsert} != "yes" ]]; then
	echo "Firing up standalone authenticator on TCP port 443 and requesting cert..."
	${LEBINARY} \
		--server https://acme-v01.api.letsencrypt.org/directory \
    	--agree-tos \
		--standalone --standalone-supported-challenges tls-sni-01 \
    	${LEOPTIONS}
fi    

if `md5sum -c /etc/letsencrypt/live/${MAINDOMAIN}/cert.pem.md5 &>/dev/null`; then
	echo "Cert has not changed, not updating controller."
	exit 0
else
	TEMPFILE=$(mktemp)
	CERTTEMPFILE=$(mktemp)

	# Identrust cross-signed CA cert needed by the java keystore for import.
	# Can get original here: https://www.identrust.com/certificates/trustid/root-download-x3.html
	cat > ${CERTTEMPFILE} <<'_EOF'
-----BEGIN CERTIFICATE-----
MIIDSjCCAjKgAwIBAgIQRK+wgNajJ7qJMDmGLvhAazANBgkqhkiG9w0BAQUFADA/
MSQwIgYDVQQKExtEaWdpdGFsIFNpZ25hdHVyZSBUcnVzdCBDby4xFzAVBgNVBAMT
DkRTVCBSb290IENBIFgzMB4XDTAwMDkzMDIxMTIxOVoXDTIxMDkzMDE0MDExNVow
PzEkMCIGA1UEChMbRGlnaXRhbCBTaWduYXR1cmUgVHJ1c3QgQ28uMRcwFQYDVQQD
Ew5EU1QgUm9vdCBDQSBYMzCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEB
AN+v6ZdQCINXtMxiZfaQguzH0yxrMMpb7NnDfcdAwRgUi+DoM3ZJKuM/IUmTrE4O
rz5Iy2Xu/NMhD2XSKtkyj4zl93ewEnu1lcCJo6m67XMuegwGMoOifooUMM0RoOEq
OLl5CjH9UL2AZd+3UWODyOKIYepLYYHsUmu5ouJLGiifSKOeDNoJjj4XLh7dIN9b
xiqKqy69cK3FCxolkHRyxXtqqzTWMIn/5WgTe1QLyNau7Fqckh49ZLOMxt+/yUFw
7BZy1SbsOFU5Q9D8/RhcQPGX69Wam40dutolucbY38EVAjqr2m7xPi71XAicPNaD
aeQQmxkqtilX4+U9m5/wAl0CAwEAAaNCMEAwDwYDVR0TAQH/BAUwAwEB/zAOBgNV
HQ8BAf8EBAMCAQYwHQYDVR0OBBYEFMSnsaR7LHH62+FLkHX/xBVghYkQMA0GCSqG
SIb3DQEBBQUAA4IBAQCjGiybFwBcqR7uKGY3Or+Dxz9LwwmglSBd49lZRNI+DT69
ikugdB/OEIKcdBodfpga3csTS7MgROSR6cz8faXbauX+5v3gTt23ADq1cEmv8uXr
AvHRAosZy5Q6XkjEGB5YGV8eAlrwDPGxrancWYaLbumR9YbK+rlmM6pZW87ipxZz
R8srzJmwN0jP41ZL9c8PDHIyh8bwRLtTcm1D9SZImlJnt1ir/md2cXjbDaJWFBM5
JDGFoqgCWjBH4d1QB7wCCZAA62RjYJsWvIjJEubSfZGL+T0yjWW06XyxV3bqxbYo
Ob8VZRzI9neWagqNdwvYkQsEjgfbKbYK7p2CNTUQ
-----END CERTIFICATE-----
_EOF

	echo "Cert has changed, updating controller..."
	md5sum /etc/letsencrypt/live/${MAINDOMAIN}/cert.pem > /etc/letsencrypt/live/${MAINDOMAIN}/cert.pem.md5 
	echo "Using openssl to prepare certificate..."
	openssl pkcs12 -export  -passout pass:aircontrolenterprise \
    	-in /etc/letsencrypt/live/${MAINDOMAIN}/cert.pem \
    	-inkey /etc/letsencrypt/live/${MAINDOMAIN}/privkey.pem \
    	-out ${TEMPFILE} -name unifi \
    	-CAfile /etc/letsencrypt/live/${MAINDOMAIN}/chain.pem -caname root
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
    	/etc/letsencrypt/live/${MAINDOMAIN}/cert.pem \
    	/etc/letsencrypt/live/${MAINDOMAIN}/chain.pem \
    	${CERTTEMPFILE}
    rm -f ${CERTTEMPFILE}
	echo "Starting Unifi controller..."
	service unifi start
	echo "Done!"
fi