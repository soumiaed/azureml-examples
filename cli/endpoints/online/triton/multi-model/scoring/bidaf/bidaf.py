import numpy as np
import tritonclient.http as tritonhttpclient
from tritonclient.utils import triton_to_np_dtype
import nltk
import numpy as np
from nltk import word_tokenize


def preprocess(text, dtype):
    """Tokenizes text for use in the bidirectional attention flow model

    Parameters
    ---------
    text : str
        Text to be tokenized

    dtype : numpy datatype
        Datatype of the resulting array

    Returns
    ---------
    (np.array(), np.array())
        Tuple containing two numpy arrays with the tokenized
        words and chars, respectively.

    From: https://github.com/onnx/models/tree/master/text/machine_comprehension/bidirectional_attention_flow  # noqa
    """
    nltk.download("punkt", quiet=True)
    tokens = word_tokenize(text)
    # split into lower-case word tokens, in numpy array with shape of (seq, 1)
    words = np.array([w.lower() for w in tokens], dtype=dtype).reshape(-1, 1)
    # split words into chars, in numpy array with shape of (seq, 1, 1, 16)
    chars = [[c for c in t][:16] for t in tokens]
    chars = [cs + [""] * (16 - len(cs)) for cs in chars]
    chars = np.array(chars, dtype=dtype).reshape(-1, 1, 1, 16)
    return words, chars


def postprocess(context_words, answer):
    """Post-process results to show the chosen result

    Parameters
    --------
    context_words : str
        Original context

    answer : InferResult
        Triton inference result containing start and
        end positions of desired answer

    Returns
    --------
    Numpy array containing the words from the context that
    answer the given query.
    """

    start = answer.as_numpy("start_pos")[0]
    end = answer.as_numpy("end_pos")[0]
    return [w.encode() for w in context_words[start : end + 1].reshape(-1)]


def run(model_args, infer, meta):
    context = model_args['context']
    query = model_args['query']
    model_metadata = meta
    input_meta = model_metadata["inputs"]
    output_meta = model_metadata["outputs"]
    np_dtype = triton_to_np_dtype(input_meta[0]["datatype"])
    cw, cc = preprocess(context, np_dtype)
    qw, qc = preprocess(query, np_dtype)

    input_mapping = {
        "query_word": qw,
        "query_char": qc,
        "context_word": cw,
        "context_char": cc,
    }

    inputs = []
    outputs = []

    # Populate the inputs array
    for in_meta in input_meta:
        input_name = in_meta["name"]
        data = input_mapping[input_name]

        input = tritonhttpclient.InferInput(input_name, data.shape, in_meta["datatype"])

        input.set_data_from_numpy(data, binary_data=False)
        inputs.append(input)

    # Populate the outputs array
    for out_meta in output_meta:
        output_name = out_meta["name"]
        output = tritonhttpclient.InferRequestedOutput(output_name, binary_data=False)
        outputs.append(output)

    # Run inference
    res = infer(inputs=inputs, outputs=outputs)
    result = postprocess(context_words=cw, answer=res)
    result = " ".join((w.decode("utf-8") for w in result)) 
    return(result)