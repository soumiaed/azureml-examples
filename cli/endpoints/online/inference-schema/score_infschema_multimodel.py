import importlib.util
from pathlib import Path
import json 

def load_handler(handler_path : Path):
    spec = importlib.util.spec_from_file_location(handler_path.parent.name, handler_path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod

def init():
    global handlers
    handler_paths = (Path(__file__).resolve().parent / "handlers").glob("*/score.py")
    handlers = {pth.parent.name : load_handler(pth) for pth in handler_paths}
    for handler in handlers.values():
        handler.init() 

def run(raw_data): 
    raw_data = json.loads(raw_data)
    models = raw_data.keys() & handlers.keys()
    return {model : handlers[model].run(raw_data[model]) for model in models}