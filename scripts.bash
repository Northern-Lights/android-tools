#!/bin/bash

# Various tools for Android development

function lsmake {
	# List make targets. Invokes 'make', so it requires a Makefile in the dir.
	# Make take a while to run for large projects.
	make -qp | awk -F':' '/^[a-zA-Z0-9][^$#\/\t=]*:([^=]|$)/ {split($1,A,/ /);for(i in A)print A[i]}'
}

function signapk {
	# Signs an apk with a key in
	# $AOSP_HOME/build/target/product/security/
	# Output name: package-keyname-signed.apk

	if [ -z $AOSP_HOME ]; then
		echo 'Please set $AOSP_HOME to the root of your AOSP directory.'
		return 1
	fi

	# Ensure that we have the signapk.jar for our platform
	srcpath="$AOSP_HOME/out/"
	jar=$(find $srcpath -type f -name signapk.jar)
	if [ -z $jar ]; then
		echo "Couldn't find signapk.jar in $srcpath"
		return 1
	fi

	# Take the args and sign the package
	key=$1
	keydir="$AOSP_HOME/build/target/product/security"
	apk=$2
	if [[ ! -n $key || ! -n $apk ]]; then
		echo "Usage: signapk <key name> <apk file>"
		return 1
	fi
	out="$(dirname $apk)/$(basename $apk | cut -d '.' -f 1)"-$key-signed.apk
	java -jar "$jar" "$keydir/$key.x509.pem" "$keydir/$key.pk8" "$apk" "$out"
}

function signdir {
	# Uses signapk on all apk files within a directory.

	
	if [ -z $AOSP_HOME ]; then
		echo "Please set $AOSP_HOME to the root of your AOSP directory."
		return 1
	fi

	key=$1
	if [ -z $key ]; then
		echo "Usage: signdir <key name>"
		return 1
	fi
	for apk in $(find . -type f -name "*.apk" ! -name "*-signed.apk"); do
		signapk "$key" "$apk"
		if [ $? -gt 0 ]; then
			echo "Error signing $apk with key $key"
		fi
	done
}
