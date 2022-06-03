#!/bin/bash

python $BASE_PATH/scoring/score.py --url_root $URL_ROOT --model_name densenet --model_args "image_url=$1" 
