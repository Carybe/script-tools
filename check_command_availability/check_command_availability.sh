#!/bin/sh

#
# Based on the bash-hackers article:
# http://wiki.bash-hackers.org/scripting/style
#

NEEDED_COMMANDS=$@

COUNTER=0

for command in $NEEDED_COMMANDS
do
	if ! hash "$command" >/dev/null 2>&1;
	then
		printf "Command not found in PATH: %s\n" "$command" >&2
		COUNTER=$(( COUNTER + 1 ))
	fi
done

if [ $COUNTER -gt 0 ]
then
	if [ $COUNTER -eq 1 ]
	then
		echo "1 command is missing in PATH, aborting\n" >&2
	fi
	printf "At least %d commands are missing in PATH, aborting\n" "$COUNTER" >&2
	exit 1
fi