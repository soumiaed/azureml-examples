FROM nvcr.io/nvidia/tritonserver:22.05-py3

CMD tritonserver --model-repository=/var/models --strict-model-config=false --model-control-mode=explicit --load-model=*