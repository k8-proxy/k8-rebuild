#!/bin/bash

export ICAP_SERVER=78.159.97.25
export MAX=5
export SOURCE_FILE=Document.pdf

if [ -n "$1" ]; then export ICAP_SERVER=$1; fi
if [ -n "$2" ]; then export MAX=$2; fi
if [ -n "$3" ]; then export SOURCE_FILE=$3; fi


for i in $(eval echo {1..$MAX})
do
   echo ">> ICAP request #$i to server $ICAP_SERVER for $SOURCE_FILE"
   ./icap-client.sh $ICAP_SERVER $SOURCE_FILE 0 $i   
done
