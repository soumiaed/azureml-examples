#%%
import os
import logging
import numpy
import joblib
from inference_schema.schema_decorators import input_schema
from inference_schema.parameter_types.numpy_parameter_type import NumpyParameterType

def init():
    global model
    # AZUREML_MODEL_DIR is an environment variable created during deployment.
    # It is the path to the model folder (./azureml-models/$MODEL_NAME/$VERSION)
    # Please provide your model's folder name if there is one
    model_path = os.path.join(
        os.getenv("AZUREML_MODEL_DIR"), "iris.pkl"
    )
    # deserialize the model file back into a sklearn model
    model = joblib.load(model_path)
    logging.info("Init complete")

@input_schema(param_name="data", param_type=NumpyParameterType(numpy.asarray([[6.0, 2.2, 5.0, 1.5], [5.2, 2.7, 3.9, 1.4]])))
def run(data):
    logging.info("Iris: request received")
    result = model.predict(data)
    logging.info("Request processed")
    return result.tolist()

# %%
