#!/bin/bash -e

#
# This script access a single website and if it has changed:
#	- creates a commit of it in DIR;
#	- send you an e-mail of such change.
#
# For such it uses kerberized authentication with mutt, assuming a well configured mutt.
#

URL=$1
DIR=$2

EMAIL=${USER}@${HOST}

KEYTAB_FILE="$HOME/$USER.keytab"

SITE=$(basename $DIR)

../check_command_availability/check_command_availability.sh "kinit curl git mutt" || exit 1

if ! [ -d $DIR ]
then
	mkdir -p $DIR
	echo "Had to create the directory: $DIR"
fi

HTTP_CODE=$(curl -s -o /dev/null -I -w "%{http_code}" $URL)

EXIT_CODE="$?"

if [ $EXIT_CODE -ne 0 ]
then
	echo "Curl could not retrieve the website and returned with code: $EXIT_CODE"
	exit $EXIT_CODE
fi

if [ $HTTP_CODE -ne 200 ]
then
	echo "The url you requested could not be accessed due the http code: $HTTP_CODE"
	exit $HTTP_CODE
fi

cd $DIR

if ! [ -e $SITE ]
then
	rm -rf site.* .g*
	git init
	curl -o $SITE -s $URL
	LOG="Wrote the first site file and initialized its repository"
	echo $LOG
	git add -A &>/dev/null
	git commit -m "$LOG" &>/dev/null
	exit 0
fi

curl -o $SITE -s $URL

DIFFERENCES=$(git diff --minimal --ignore-space-at-eol --ignore-space-change --ignore-all-space --ignore-blank-lines)

if [ "$DIFFERENCES" ]
then
	echo "Updated site file"
	git add -A &> /dev/null
	EXIT_CODE="$?"

	if [ $EXIT_CODE -ne 0 ]
	then
		echo "Git could not add the new files and returned with code: $EXIT_CODE"
		exit $EXIT_CODE
	fi

	git commit -m "$DIFFERENCES" &> /dev/null
	EXIT_CODE="$?"

	if [ $EXIT_CODE -ne 0 ]
	then
		echo "Git could not commit the files changes and returned with code: $EXIT_CODE"
		exit $EXIT_CODE
	fi

	# To generate the keytab:
	# $ ktutil
	# ktutil:  addent -password -p $USER@$HOST -k 1 -e aes256-cts-hmac-sha1-96
	# Password for $USER@$HOST:
	# ktutil:  wkt $KEYTAB_FILE

	kinit -kt $KEYTAB_FILE ${USER}@${HOST}
	EXIT_CODE="$?"

	if [ $EXIT_CODE -ne 0 ]
	then
		echo "Script could not initialize the kerberos key and returned with code: $EXIT_CODE"
		exit $EXIT_CODE
	fi

	mutt -s "$URL has changed!" $EMAIL <<EOF
$DIFFERENCES
EOF

fi

exit 0