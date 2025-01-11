#!/bin/bash

if [ "$#" -ne 2 ]; then
	echo "Usage $0 <SVN_URL> <output_file>"
	exit 1
fi


#svn repository URL
SVN_URL=$1

#output file with committer list
OUTPUT_FILE=$2

#temperory file to store output
TEMP_FILE=$(mktemp)

echo "Fetching SVN committers from $SVN_URL ..."
svn log "$SVN_URL" --quiet | grep -E '^r[0-9]+' | awk '{print $3}' | sort | uniq > "$TEMP_FILE"

echo "generating committer file"
> "$OUTPUT_FILE" #empty/create file

while read -r COMMITTER; do
	if [ -n "$COMMITTER" ]; then
		echo "$COMMITTER = $COMMITTER <${COMMITTER}@emaildomain.com>" >> "$OUTPUT_FILE"
	fi
done < "$TEMP_FILE"

rm -f "$TEMP_FILE"

echo "Committer file generated successfully"
