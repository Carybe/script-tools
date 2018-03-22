#!/bin/bash -e

#
# This script access a website and all children links it has connections to and if any of those has changed:
#	- creates a commit of it in DIR;
#	- send you an e-mail of such change.
#
# For such it uses kerberized authentication with mutt, assuming a well configured mutt.
#

if [ $# -eq 0 ]
then
        cat <<EOF
Usage: $(basename "$0") url out_dir
where:
	'url' can be a single webpage or a directory ended with a trailing slash '/'
EOF

	exit 0
fi

URL=$1
DIR=$2

EMAIL=${USER}@${HOST}

KEYTAB_FILE="$HOME/$USER.keytab"

DOWN_DIR="${URL%/*/}"
DOWN_DIR="${URL#[Hh]*//}"
ROOT_DOWN_DIR="$(echo $DOWN_DIR | cut -d '/' -f1)"

# wget mirroring only works right with directories, for single pages, use curl
if [ "${URL: -1}" != "/" ]
then
	echo "This version of the script only works with directories, please be sure that the url provided has a trailing slash '/'"
	exit 1
fi

# Curl
#DOWNLOAD="curl -o $FILE -s "
# Wget-new
# DOWNLOAD="wget -e robots=off --random-wait --recursive --level=inf --timestamping --no-remove-listing --tries=20  --no-if-modified-since --no-use-server-timestamps --no-parent --timeout=10 --restrict-file-names=unix --ignore-length --user-agent='Mozilla/5.0 (Macintosh; Intel Mac OS X 10.11; rv:58.0) Gecko/20100101 Firefox/58.0' --no-check-certificate --convert-links --quiet "
DOWNLOAD="wget -e robots=off --random-wait --recursive --level=inf --timestamping --no-remove-listing --tries=20 --no-use-server-timestamps --no-parent --timeout=10 --restrict-file-names=unix --ignore-length --user-agent='Mozilla/5.0 (Macintosh; Intel Mac OS X 10.11; rv:58.0) Gecko/20100101 Firefox/58.0' --no-check-certificate --convert-links --quiet "

SITE=$(basename $URL)

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
	rm -rf $ROOT_DOWN_DIR .g*
	git init
	$DOWNLOAD $URL || true
	cp -R $DOWN_DIR $DIR
	rm -rf $ROOT_DOWN_DIR
	LOG="Wrote the first site file and initialized its repository"
	echo $LOG
	git add -A &>/dev/null
	git commit -m "$LOG" &>/dev/null
	exit 0
fi

$DOWNLOAD $URL || true
cp -R $DOWN_DIR $DIR
rm -rf $ROOT_DOWN_DIR

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