from inference_schema.schema_decorators import input_schema
from inference_schema.parameter_types.standard_py_parameter_type import StandardPythonParameterType

import score_direct, score_direct2

def init():
    global mod_map
    mod_map = {"score_direct" : score_direct,
               "score_direct2" : score_direct2}

    for mod in mod_map.values():
        mod.init() 

@input_schema(param_name="model_name", param_type=StandardPythonParameterType("model_name"))
def run(model_name, payload):
    if model_name in mod_map.keys():
        return mod_map[model_name].run(payload)
    else:
        return f"No model named {model_name}"

