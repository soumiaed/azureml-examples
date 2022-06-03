from pathlib import Path
import numpy as np
import io
import requests
from PIL import Image
import tritonclient.http as tritonhttpclient
import tritonclient.http as tritonhttpclient
import requests


def preprocess(img_content):
    """Pre-process an image to meet the size, type and format
    requirements specified by the parameters.
    """
    c = 3
    h = 224
    w = 224

    img = Image.open(io.BytesIO(img_content))

    sample_img = img.convert("RGB")

    resized_img = sample_img.resize((w, h), Image.Resampling.BILINEAR)
    resized = np.array(resized_img)
    if resized.ndim == 2:
        resized = resized[:, :, np.newaxis]

    typed = resized.astype(np.float32)

    # scale for INCEPTION
    scaled = (typed / 128) - 1

    # Swap to CHW
    ordered = np.transpose(scaled, (2, 0, 1))

    # Channels are in RGB order. Currently model configuration data
    # doesn't provide any information as to other channel orderings
    # (like BGR) so we just assume RGB.
    img_array = np.array(ordered, dtype=np.float32)[None, ...]

    return img_array

def postprocess(max_label):
    """Post-process results to show the predicted label."""

    label_path = Path(__file__).parent / "densenet_labels.txt"
    label_file = open(label_path, "r")
    labels = label_file.read().split("\n")
    label_dict = dict(enumerate(labels))
    final_label = label_dict[max_label]
    return f"{max_label} : {final_label}"


def run(model_args, infer, meta):
    img_content = requests.get(model_args['image_url']).content
    img_data = preprocess(img_content)
    input = tritonhttpclient.InferInput("data_0", img_data.shape, "FP32")
    input.set_data_from_numpy(img_data)
    output = tritonhttpclient.InferRequestedOutput("fc6_1")
    result = infer(inputs=[input], outputs=[output])
    max_label = np.argmax(result.as_numpy("fc6_1"))
    label_name = postprocess(max_label)
    return(label_name)