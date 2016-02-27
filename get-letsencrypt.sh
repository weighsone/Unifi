#!/usr/bin/env bash
# Install LetsEncrypt official client on UNIX/Linux using a bash script.
# v1.0 - 02/27/2016
# By Brielle Bruns <bruns@2mbit.com>
# http://www.sosdg.org

# Use like:  gen-letsencrypt.sh -g
#
# Flags:
# -g  - use git to download
# -t  - download master tarball

# Where to store the LetsEncrypt package
DESTDIR="/usr/src/"

ZIPURL="https://codeload.github.com/letsencrypt/letsencrypt/zip/master"
GITREPO="https://github.com/letsencrypt/letsencrypt"

if [ $# -eq 0 ]; then
	echo "Command Help:"
	echo "-g : download using git from master repo"
	echo "-z : download zip from main repo and extract"
    exit 0
fi


while getopts "gz" opt; do
    case $opt in
    g) downloadtype="git";;
	z) downloadtype="zip";;
    esac
done

cd ${DESTDIR}

case $downloadtype in
	git)
		echo "Cloning repo into ${DESTDIR}..."
		git clone ${GITREPO}
		;;
	zip)
		echo "Downloading ${ZIPURL} into ${DESTDIR}"
		curl -o letsencrypt.zip ${ZIPURL}
		unzip letsencrypt.zip
		;;
esac