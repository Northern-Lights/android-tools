#!/bin/bash

# Various tools for Android development

function lsmake {
	# List make targets. Invokes 'make', so it requires a Makefile in the dir.
	# Make take a while to run for large projects.
	make -qp | awk -F':' '/^[a-zA-Z0-9][^$#\/\t=]*:([^=]|$)/ {split($1,A,/ /);for(i in A)print A[i]}'
}

function envsetup {
	LUNCHNUMBER=$1
	source build/envsetup.sh
	if [ $? -ne 0 ]; then
		echo "Failed to source envsetup"
		return 1
	fi
	lunch $LUNCHNUMBER
	if [ $? -ne 0 ]; then
		echo "Failed to run lunch"
		return 2
	fi
}

function buildandflash {
# Builds and flashes AOSP or the specified make target
	TARGET=$1
	if [ -z $TARGET ]; then
		echo "WARNING: building all without a specific target"
		sleep 3
	fi

	if [ -z $(which flashsystem.bash) ]; then
		echo "flashsystem.bash needs to be in your PATH"
		return 1
	fi

	if [ -z $OUT ]; then
		echo "Looks like lunch was not run. Please set up the build environment."
		return 2
	fi

	croot
	make -j8 $TARGET && cd $OUT && flashsystem.bash
	if [ $? -ne 0 ]; then
		echo "Failed to make and/or flash the system image"
		return 3
	fi
}

function buildandflashsystem {
# Builds and flashes using the systemimage target
	buildandflash systemimage
	return $?
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

function installsignedapp {
# Uninstalls an app, signs an apk, and installs it
	app=$1
	if [ -z $app ]; then
		echo "Choose an app to uninstall"
		return 1
	fi
	adb uninstall $app
	signdir 'platform' && adb install app-debug-platform-signed.apk && adb shell "am start -n $app/.Main"
	return $?
}
