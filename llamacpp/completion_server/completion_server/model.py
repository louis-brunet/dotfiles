import logging
import os

from llama_cpp import Llama

from completion_server.entities import CompletionRequest

_MODEL_ALIASES = {
    "qwen2.5-coder:1.5b-instruct": "qwen2.5-coder-1.5b-instruct-q8_0",
    "qwen2.5-coder:7b-instruct": "qwen2.5-coder-7b-instruct-q5_k_m",
    "codellama:7b": "codellama-7b.Q8_0",
}

_module_logger = logging.getLogger(__name__)


def _default_models_directory() -> str:
    script_path = os.path.realpath(__file__)
    llamacpp_dir = os.path.dirname(os.path.dirname(os.path.dirname(script_path)))
    models_directory = os.path.join(llamacpp_dir, "models")  # ../../models
    return models_directory


def _requested_model_to_model_path(
    model_name: str, models_directory: str = _default_models_directory()
) -> str:
    alias = _MODEL_ALIASES.get(model_name)

    if alias:
        model_name = alias

    return os.path.join(models_directory, f"{model_name}.gguf")


def load_model(model_name_or_alias: str, n_ctx: int, verbose: bool = False) -> Llama:
    """
    Parameters:
        model_name_or_alias: .gguf extension is always appended, model directory is prepended.
        n_ctx: context length for the model.
        verbose: whether to log llamacpp output.

    Returns:
         An instance of the Llama class from llama_cpp. This is a high-level wrapper around the llama model.
    """

    model_path = _requested_model_to_model_path(model_name=model_name_or_alias)
    # logger = logging.getLogger(__name__)
    logger = _module_logger.getChild(load_model.__name__)
    logger.info(f"Loading model from path '{model_path}'")

    try:
        return Llama(
            model_path=model_path,
            n_ctx=n_ctx,
            n_gpu_layers=-1,
            flash_attn=True,
            n_threads=12,
            # n_batch=n_batch
            # tokenizer=,
            # chat_format=chat_format,
            verbose=verbose,
        )
    except ValueError as e:
        raise ModelNotFoundError(model_path)
    except Exception as e:
        raise RuntimeError(f"Failed to load model from path '{model_path}': {e}")


class ModelNotFoundError(Exception):
    def __init__(self, model_path: str):
        super().__init__(f"Model not found at path: {model_path}")


def can_model_respond_to_request(llm: Llama, request: CompletionRequest) -> bool:
    requested_path = _requested_model_to_model_path(request.model)

    return llm.model_path == requested_path and llm.n_ctx() == request.n_ctx
