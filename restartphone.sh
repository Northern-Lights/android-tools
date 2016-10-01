#!/system/bin/sh

phoneline=$(ps | grep -E "^radio" | grep -E "phone$")
if [ $? -ne 0 ]; then
	echo "Unable to find phone process."
	exit 1
fi

_pid=${phoneline#radio *}
pid=$(echo -n $_pid | cut -d " " -f 1)

test $pid -gt 0 && kill $pid
