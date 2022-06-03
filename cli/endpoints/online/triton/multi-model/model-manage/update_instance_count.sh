#!/bin/bash

MODEL=$1 
INSTANCE_COUNT=$2 

NEW_CONFIG=`curl -s -X GET "$URL_ROOT/v2/models/$MODEL/config" -H "Authorization: Bearer $TOKEN" | sed -e "s/\"/'/g" -e "1s/\('KIND_CPU' \?, \?'count'\) \?: \?[0-9]\+/\1:$INSTANCE_COUNT/g"`
curl -X POST "$URL_ROOT/v2/repository/models/$MODEL/load" -H "Authorization: Bearer $TOKEN" -d "{\"parameters\": {\"config\":\"$NEW_CONFIG\"}}"