Lets Encrypt Scripts

Public Git URL: https://source.sosdg.org/brielle/lets-encrypt-scripts

By: Brielle Bruns <bruns@2mbit.com>

These are various scripts to make LetsEncrypt easier to use.

Main Scripts
=============================================================
gen-cert.sh  - Main script to make it easy to generate LE certs for domain(s)

gen-unifi-cert.sh - Script to add LE cert to a Unifi controller

Support Files
=============================================================
DSTROOTCAX3.txt - Root CA cert needed for use with the gen-unifi-cert.sh script

apache-le-alias.conf - Use with apache for LE well-known alias config

apache-le-proxy.conf - Use with apache for LE well-known proxy config

How To Use
=============================================================

gen-unifi-cert.sh
	1) Do initial cert generation:
	
		gen-unifi-cert.sh -e email@address.com -d unifi.somedomain.com -d unifi.someotherdomain.com
		
	2) Put in /etc/cron.weekly/renew-unifi-ssl if everything works okay:
	
		/path/to/script/gen-unifi-cert.sh -r -d unifi.somedomain.com -d unifi.someotherdomain.com
		
	3) Script will now run weekly and renew the certificate if necessary ( <30 days remain)
		and restart unifi only if cert has been renewed.