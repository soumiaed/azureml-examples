#!/bin/bash

curl -X POST -H "Authorization: Bearer $TOKEN" $URL_ROOT/v2/repository/index | jq 