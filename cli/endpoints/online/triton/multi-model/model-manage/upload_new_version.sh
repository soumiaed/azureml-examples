#!/bin/bash

cp $BASE_PATH/model-manage/densenet2_conf_template.json $BASE_PATH/model-manage/conf.json
base64 -w 0 models/densenet/1/model.onnx >> $BASE_PATH/model-manage/conf.json
echo \"\}\} >> $BASE_PATH/model-manage/conf.json
curl -X POST $URL_ROOT/v2/repository/models/densenet/load -d @"$BASE_PATH/model-manage/conf.json" -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN"