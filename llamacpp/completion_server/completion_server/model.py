import logging
import os

from llama_cpp import Llama

_MODEL_ALIASES = {
    "qwen2.5-coder:1.5b-instruct": "qwen2.5-coder-1.5b-instruct-q8_0",
    "qwen2.5-coder:7b-instruct": "qwen2.5-coder-7b-instruct-q5_k_m",
    "codellama:7b": "codellama-7b.Q8_0",
}


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


def load_model(model_name_or_alias: str, n_ctx: int) -> Llama:
    """
    Args:
        model_name_or_alias: .gguf extension is always appended, model directory is prepended.
        n_ctx: context length for the model.
    """
    model_path = _requested_model_to_model_path(model_name=model_name_or_alias)
    logger = logging.getLogger(__name__)
    logger.info(f"Loading model from path '{model_path}'")

    return Llama(
        model_path=model_path,
        n_ctx=n_ctx,
        n_gpu_layers=-1,
        flash_attn=True,
        n_threads=12,
        # n_batch=n_batch
        # tokenizer=,
        # chat_format=chat_format,
    )
