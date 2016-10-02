#!/bin/bash

if [ -z $DEVID ]; then
	echo "Please define DEVID with your Android device's ADB ID number"
	exit 1
fi

if [ -z $OUT ]; then
	echo "OUT not set. You probably haven't run lunch."
	exit 1
fi

#DEVID=
PARTITION=system
FNAME=$PARTITION.img

# Make sure we are in the output dir for the android target
if [[ $(pwd) == $OUT ]]; then

	# Make sure the image file exists
	if [ ! -s $FNAME ]; then
		echo "File $FNAME does not exist, cannot proceed."
		exit 3
	fi

	# Proceed with the fastboot flash
	echo "Rebooting device $DEVID"
	adb -s $DEVID reboot bootloader
	echo "Flashing $PARTITION with $FNAME"
	fastboot flash $PARTITION $FNAME
	if [ $? -gt 0 ]; then
		echo "Flashing /$PARTITION failed"
		exit 1
	fi
		
	echo "Successfully flashed /$PARTITION"
	echo "Rebooting device."
	fastboot reboot
	exit 0
else
	echo "Please change to the '\$OUT' directory"
	exit 2
fi
