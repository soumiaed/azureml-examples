#!/bin/bash

curl -X POST -H "Authorization: Bearer $TOKEN" -d @"$(dirname $0)/fashion_load.json" $URL_ROOT/v2/repository/models/fashion/load -i