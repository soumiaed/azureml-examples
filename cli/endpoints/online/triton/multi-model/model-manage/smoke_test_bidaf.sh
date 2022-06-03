#!/bin/bash

python $BASE_PATH/scoring/score.py --url_root $URL_ROOT --model_name bidaf-9 --model_args "context=$1" "query=$2"
