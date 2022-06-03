#!/bin/bash

ENDPT_NAME=$1

if [ -z $ENDPT_NAME ]; then
    AUTH_HEADER=""
    SCORING_URI="http://localhost:8000/"
else
    AUTH_HEADER="Authorization: Bearer $(az ml online-endpoint get-credentials -n $ENDPT_NAME -o tsv --query primaryKey)"
    SCORING_URI=$(az ml online-endpoint show -n $ENDPT_NAME -o tsv --query scoring_uri)
fi 

is_ready () {
    curl -s -H "$AUTH_HEADER" "${SCORING_URI}$1" -w "%{http_code}" | sed -e 's/200/True/g' -e 's/[0-9]\+/False/g'
}

echo "Is server ready - $(is_ready v2/health/ready)"

echo "Is model ready - $(is_ready v2/models/fashion/ready)"

res=`curl -s -d @scoring/fashion/input.json -H "Content-Type: application/json" -H "$AUTH_HEADER" ${SCORING_URI}v2/models/fashion/infer`

if [[ $res == *"error"* ]] || [ -z $res ]; then
    echo "Server error: $res"
else
    echo $res | sed -n "s/^.*\"data\":\[\(.*\)\]}]}/\1/p" | tr , \\n | paste - scoring/fashion/fashion_labels.txt  | sort -nr | head -1 | cut -f2
fi

