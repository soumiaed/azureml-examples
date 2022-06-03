#!/bin/bash

set -e 

# <set_variables>
export ENDPOINT_NAME="<ENDPOINT_NAME>"
export ACR_NAME="<CONTAINER_REGISTRY_NAME>"
# </set_variables>

export ENDPOINT_NAME=endpt-moe-`echo $RANDOM`
export ACR_NAME=$(az ml workspace show --query container_registry -o tsv | cut -d'/' -f9-)

# <install_requirements>
pip install numpy
pip install tritonclient[http]
pip install pillow
pip install gevent
pip install nltk 
# <?install_requirements>

# <make_working_directory>
export BASE_PATH=$(pwd)/endpoints/online/custom-container/triton-multimodel
rm -rf $BASE_PATH && cp -r endpoints/online/triton/multi-model/ $BASE_PATH/
# </make_working_directory> 

# <compile_assets>
cp -r endpoints/online/triton/single-model/models/model_1 $BASE_PATH/models/densenet/
mkdir -p $BASE_PATH/models/bidaf-9/1 && curl -L https://aka.ms/bidaf-9-model -o $BASE_PATH/models/bidaf-9/1/model.onnx
cp $(dirname $BASE_PATH)/triton-multimodel*.* $BASE_PATH/
cp endpoints/online/triton/single-model/densenet_labels.txt $BASE_PATH/scoring/densenet
# </compile_assets>

# <build_locally>
docker build -t "azureml-examples/triton-multimodel:1" -f $BASE_PATH/triton-multimodel.dockerfile $BASE_PATH
docker run -d -v $BASE_PATH/models:/var/models -p 8000:8000 -p 8001:8001 -p 8002:8002 -it "azureml-examples/triton-multimodel:1" 
# </build_locally> 

# <set_local_endpoint>
export URL_ROOT="http://localhost:8000"
export TOKEN=""
# </set_local_endpoint>

# <check_local_models> 
$BASE_PATH/model-manage/check_models.sh
# </check_local_models>

# <smoke_test_fashion_local> 
$BASE_PATH/model-manage/smoke_test_fashion.sh
# </smoke_test_fashion_local>

# <unload_fashion_local> 
$BASE_PATH/model-manage/unload_fashion.sh
$BASE_PATH/model-manage/check_models.sh
# </unload_fashion_local>

# <load_fashion_local> 
$BASE_PATH/model-manage/load_fashion.sh
$BASE_PATH/model-manage/check_models.sh
# </load_fashion_local>

# <smoke_test_densenet_local> 
$BASE_PATH/model-manage/smoke_test_densenet.sh https://aka.ms/peacock-pic
# </smoke_test_densenet_local>

# <smoke_test_bidaf_local>
$BASE_PATH/model-manage/smoke_test_bidaf.sh  "A quick brown fox jumped over the lazy dog." "What did the fox do?"
# </smoke_test_bidaf_local> 

# <build_acr>
az acr login
az acr build -t "azureml-examples/triton-multimodel:1" -f $BASE_PATH/triton-multimodel.dockerfile -r $ACR_NAME $BASE_PATH
# </build_acr>

# <register_model>
az ml model create --name triton-multimodel --version 1 --path $BASE_PATH/models
# </register_model> 

# <create_endpoint>
ENDPOINT_YML=$BASE_PATH/triton-multimodel-endpoint.yml 
sed -i "s/{{endpt_name}}/$ENDPOINT_NAME/g;" $ENDPOINT_YML
az ml online-endpoint create -f $ENDPOINT_YML
# </create_endpoint>

# <get_endpoint_status>
az ml online-endpoint show -n $ENDPOINT_NAME
# </get_endpoint_status>

# check if create was successful
endpoint_status=`az ml online-endpoint show --name $ENDPOINT_NAME --query "provisioning_state" -o tsv`
echo $endpoint_status
if [[ $endpoint_status == "Succeeded" ]]
then
  echo "Endpoint created successfully"
else
  echo "Endpoint creation failed"
  exit 1
fi

# <create_deployment>
DEPLOYMENT_YML=$BASE_PATH/triton-multimodel-deployment.yml 
sed -i "s/{{acr_name}}/$ACR_NAME/g;\
        s/{{endpt_name}}/$ENDPOINT_NAME/g;" $DEPLOYMENT_YML
az ml online-deployment create -f $DEPLOYMENT_YML --all-traffic
# </create_deployment>

# <get_deployment_status>
az ml online-deployment show -e $ENDPOINT_NAME -n triton-multimodel 
# </get_deployment_status>

deploy_status=`az ml online-deployment show --name triton-multimodel  --endpoint $ENDPOINT_NAME --query "provisioning_state" -o tsv`
echo $deploy_status
if [[ $deploy_status == "Succeeded" ]]
then
  echo "Deployment completed successfully"
else
  echo "Deployment failed"
  exit 1
fi

# <get_scoring_uri> 
export URL_ROOT=$(az ml online-endpoint show -n $ENDPOINT_NAME -o tsv --query scoring_uri | sed "s/.\$//")
# </get_scoring_uri> 

# <get_token> 
export TOKEN=$(az ml online-endpoint get-credentials -n $ENDPOINT_NAME -o tsv --query primaryKey)
# </get_token> 

# <check_models> 
$BASE_PATH/model-manage/check_models.sh
# </check_models>

# <smoke_test_fashion> 
$BASE_PATH/model-manage/smoke_test_fashion.sh
# </smoke_test_fashion>

# <unload_fashion> 
$BASE_PATH/model-manage/unload_fashion.sh
$BASE_PATH/model-manage/check_models.sh
# </unload_fashion>

# <load_fashion> 
$BASE_PATH/model-manage/load_fashion.sh
$BASE_PATH/model-manage/check_models.sh
# </load_fashion>

# <smoke_test_densenet> 
$BASE_PATH/model-manage/smoke_test_densenet.sh https://aka.ms/peacock-pic
# </smoke_test_densenet>

# <smoke_test_bidaf>
$BASE_PATH/model-manage/smoke_test_bidaf.sh "A quick brown fox jumped over the lazy dog." "What did the fox do?"
# </smoke_test_bidaf> 

# <update_instance_count>
$BASE_PATH/model-manage/update_instance_count.sh bidaf-9 8 
# </update_instance_count> 

# <upload_new_version>
$BASE_PATH/model-manage/upload_new_version.sh
# </upload_new_version> 

# <check_new_version> 
$BASE_PATH/model-manage/check_models.sh
# </check_new_version> 

# <test_new_version>  
$BASE_PATH/model-manage/smoke_test_densenet.sh https://aka.ms/peacock-pic
# </test_new_version>  

# <delete_endpoint>
az ml online-endpoint delete -n $ENDPOINT_NAME --yes
# </delete_endpoint>

# rm -rf $BASE_PATH