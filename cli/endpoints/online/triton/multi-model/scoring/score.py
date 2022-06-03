import argparse
import gevent.ssl
import tritonclient.http as tritonhttpclient
from tritonclient.utils import triton_to_np_dtype
from pathlib import Path
import importlib.util
import functools 

model_modules = {"bidaf-9" : "bidaf/bidaf.py",
                 "densenet" : "densenet/densenet.py"}

def load_module(model_name):
    pth = Path(__file__).parent / model_modules[model_name]
    spec = importlib.util.spec_from_file_location(pth.stem, pth)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--url_root")
    parser.add_argument("--token")
    parser.add_argument("--model_version", type=str, default="1")
    parser.add_argument("--model_name", type=str)
    parser.add_argument("--model_args", nargs="*")
    args = parser.parse_args()
    args.model_args = {k:v for k,v in (pair.split("=", 1) for pair in args.model_args)} if args.model_args else {}
    return args

def get_client(url_root):
    if url_root[:5] == "https":
        return tritonhttpclient.InferenceServerClient(
                    url=url_root[8:],
                    ssl=True,
                    ssl_context_factory=gevent.ssl._create_default_https_context)
    elif url_root[:4] == "http":
        return tritonhttpclient.InferenceServerClient(url=url_root[7:])
    else: 
        raise ValueError("Only http or https supported by this script.")

def auth_header(headers=None, token=None):
    headers = {} if not headers else headers 
    if token: 
        headers["Authorization"] = f"Bearer {token}"
    return headers

def check_readiness(client, headers, model_name, model_version):
    health_ctx = client.is_server_ready(headers=headers)
    print("Is server ready - {}".format(health_ctx))

    status_ctx = client.is_model_ready(model_name, model_version, headers=headers)
    print("Is model ready - {}".format(status_ctx))

def main():
    args = parse_args()
    model = load_module(args.model_name)
    client = get_client(args.url_root)
    headers = auth_header(token=args.token if "token" in args else None)
    check_readiness(client, headers, args.model_name, args.model_version)
    partial = lambda func : functools.partial(func,
                                              model_name=args.model_name,
                                              model_version=args.model_version,
                                              headers=headers) 
    infer = partial(client.infer)
    meta = partial(client.get_model_metadata)() 
    result = model.run(meta=meta, infer=infer, model_args=args.model_args)
    print(result)

if __name__ == "__main__": 
    main()