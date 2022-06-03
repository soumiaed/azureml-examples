#!/bin/bash

#set -e

#TODO:
# Remove local
# pip install scikit-learn

# <set_variables> 
export ENDPOINT_NAME="<ENDPOINT_NAME>"
# </set_variables> 

export ENDPOINT_NAME="endpt-$RANDOM"
export BASE_PATH=endpoints/online/inference-schema

#TODO: 
#export ENDPOINT_NAME="endpt-18724"

# <copy_scoring_files>
rm -rf $BASE_PATH/multimodel && mkdir -p $BASE_PATH/multimodel/{code,models}
ls $BASE_PATH | sed -n "s#score_\(.*\)_inference_schema.py#mkdir -p $BASE_PATH/multimodel/code/handlers/\1 \&\& cp $BASE_PATH/& $BASE_PATH/multimodel/code/handlers/\1/score.py#p" | bash
cp $BASE_PATH/score_infschema_multimodel.py $BASE_PATH/multimodel/code/score.py
# </copy_scoring_files> 

# <copy_model1>
cp -r endpoints/online/model-1/model $BASE_PATH/multimodel/models
# </copy_model1> 

# <generate_iris_model>
python $BASE_PATH/train_iris.py --sample-input $BASE_PATH/multimodel/iris-sample-input.json --model-pkl $BASE_PATH/multimodel/models/iris.pkl
# </generate_iris_model>

# <compress_models>
tar -czvf $BASE_PATH/multimodel/models.tar.gz -C $BASE_PATH/multimodel/models . 
# </compress_models>

# <combine_sample_input>
cat $BASE_PATH/multimodel/iris-sample-input.json endpoints/online/model-1/sample-request.json | sed -e "1s/data/iris/" -e "1s/data/model_1/" -e "s/}{/, /" > $BASE_PATH/multimodel/multimodel-sample-input.json
# </combine_sample_input>

# <create_endpoint>
az ml online-endpoint create -n $ENDPOINT_NAME -f $BASE_PATH/inference-schema-multimodel-endpoint.yml ##--local
# </create_endpoint>

# <create_deployment>
az ml online-deployment create -e $ENDPOINT_NAME -f $BASE_PATH/inference-schema-multimodel-deployment.yml ##--local
# </create_deployment>

az ml online-deployment get-logs -e $ENDPOINT_NAME -n inference-schema-multimod ##--local

az ml online-deployment get-logs -e endpt-18724 -n inference-schema-multimod ##--local