#!/bin/bash

curl -X POST -H "Authorization: Bearer $TOKEN" -d @"$(dirname $0)/../scoring/fashion/input.json" $URL_ROOT/v2/models/fashion/versions/1/infer | jq