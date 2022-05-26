#!/bin/bash

set -e

# <set_variables> 
export ENDPOINT_NAME="<ENDPOINT_NAME>"d
# </set_variables> 

export ENDPOINT_NAME="endpt-$RANDOM"
export BASE_PATH=endpoints/online/inference-schema

# <initialize_build_dirs>
rm -rf $BASE_PATH/multimodel/{code,models} && mkdir -p $BASE_PATH/multimodel/{code,models}
# </setup_build_dirs> 

# <copy_scoring_files>
cp $BASE_PATH/score-*.py $BASE_PATH/multimodel/code && touch $BASE_PATH/multimodel/code/__init__.py
# </copy_scoring_files> 

# <copy_model1>
cp $BASE_PATH/score-*.py $BASE_PATH/multimodel/code && touch $BASE_PATH/multimodel/code/__init__.py
# </copy_model1> 

# <generate_iris>

# </generate_iris> 

# <create_endpoint>
az ml online-endpoint create -n $ENDPOINT_NAME -f $BASE_PATH/inference-schema-model1-endpoint.yml
# </create_endpoint>

# <create_deployment>
az ml online-deployment create -e $ENDPOINT_NAME -f $BASE_PATH/inference-schema-model1-deployment.yml
# </create_deployment>