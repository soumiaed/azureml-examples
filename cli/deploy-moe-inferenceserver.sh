#!/bin/bash

# TODO
#set -e

# <set_variables> 
export ENDPOINT_NAME="<ENDPOINT_NAME>"
# </set_variables> 

export ENDPOINT_NAME="endpt-$RANDOM"
export BASE_PATH=endpoints/online/inference-schema

# <create_endpoint>
az ml online-endpoint create -n $ENDPOINT_NAME -f $BASE_PATH/inference-schema-model1-endpoint.yml --local 
# </create_endpoint>

#TODO: Remove local 
# <get_status>
az ml online-endpoint show -n $ENDPOINT_NAME --local 
# </get_status>

# check if create was successful
endpoint_status=`az ml online-endpoint show --name $ENDPOINT_NAME  --local --query "provisioning_state" -o tsv`
echo $endpoint_status
if [[ $endpoint_status == "Succeeded" ]]
then
  echo "Endpoint created successfully"
else
  echo "Endpoint creation failed"
  exit 1
fi


# TODO: Change local, add all traffic 
# <create_deployment>
az ml online-deployment create -e $ENDPOINT_NAME -f $BASE_PATH/inference-schema-model1-deployment.yml  --local
# </create_deployment>

deploy_status=`az ml online-deployment show --name inference-schema-model1 --endpoint $ENDPOINT_NAME --local --query "provisioning_state" -o tsv`
echo $deploy_status
if [[ $deploy_status == "Succeeded" ]]
then
  echo "Deployment completed successfully"
else
  echo "Deployment failed"
  # <delete_endpoint_and_model>
  az ml online-endpoint delete -n $ENDPOINT_NAME -y --local 
  exit 1
fi

# Remove local
# <invoke_endpoint>
az ml online-endpoint invoke -n $ENDPOINT_NAME --request-file endpoints/online/model-1/sample-request.json --local
# </invoke_endpoint>

# <get_scoring_uri>
SCORING_URI=$(az ml online-endpoint show -n $ENDPOINT_NAME --query scoring_uri --local -o tsv)
# </get_scoring_uri>

# <get_key>
KEY=$(az ml online-endpoint get-credentials -n $ENDPOINT_NAME --query primaryKey --local -o tsv)
# </get_key>

# <invoke_endpoint_with_curl>
curl -H  "Content-Type: application/json" -H "Authorization: Bearer $KEY" -d @endpoints/online/model-1/sample-request.json $SCORING_URI
# </invoke_endpoint_with_curl>


# <delete_endpoint>
az ml online-endpoint delete -y -n $ENDPOINT_NAME
# </delete_endpoint>
