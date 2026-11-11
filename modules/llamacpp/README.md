# Download model from HF
## Script
```bash
./scripts/download_model.py --help

# if no merge is needed
./scripts/download_model.py --hf-repo "Qwen/Qwen2.5-Coder-1.5B-Instruct-GGUF" --hf-files "qwen2.5-coder-1.5b-instruct-q8_0.gguf" --output-file-path "models/qwen2.5-coder-1.5b-instruct-q8_0.gguf"

# if merge is needed
./scripts/download_model.py --hf-repo "Qwen/Qwen2.5-Coder-7B-Instruct-GGUF" --hf-files "qwen2.5-coder-7b-instruct-q5_k_m*.gguf" --merge --output-file-path "models/qwen2.5-coder-7b-instruct-q5_k_m.gguf"
```

## Manually
From instructions in https://huggingface.co/Qwen/Qwen2.5-Coder-7B-Instruct-GGUF :

```bash
hf_repo=Qwen/Qwen2.5-Coder-7B-Instruct-GGUF
hf_files="qwen2.5-coder-7b-instruct-q5_k_m*.gguf" 
huggingface-cli download "$hf_repo" --include "$hf_files" 

# hf_repo=Qwen/Qwen2.5-Coder-7B-Instruct-GGUF
# hf_files="qwen2.5-coder-7b-instruct-q5_k_m*.gguf" 
# models_dir=./models
# huggingface-cli download "$hf_repo" --include "$hf_files" --local-dir "$models_dir" --local-dir-use-symlinks False

# (Optional) Merge: For split files, you need to merge them first with the command llama-gguf-split as shown below:
# ./llama-gguf-split --merge <first-split-file-path> <merged-file-path>

# NOTE: replace with snapshot sha
models_dir=~/.cache/huggingface/hub/models--Qwen--Qwen2.5-Coder-7B-Instruct-GGUF/snapshots/a5c0a364b47c2427191f9eb97e9fd0dc8d1d1df9
llama-gguf-split --merge "$models_dir"/qwen2.5-coder-7b-instruct-q5_k_m-00001-of-00002.gguf qwen2.5-coder-7b-instruct-q5_k_m.gguf

```

# Serve model

## Running for ggml-org/llama.vim plugin

> [!NOTE]
> use qwen2.5-coder, not qwen2.5-coder-instruct

### Using presets:

```bash
# With < 8GB VRAM
llama-server --fim-qwen-1.5b-default

# With < 16GB VRAM
llama-server --fim-qwen-3b-default

# With > 16GB VRAM
llama-server --fim-qwen-7b-default

## Speculative
# use Qwen 2.5 Coder 7B + 0.5B draft for speculative decoding
llama-server --fim-qwen-7b-spec                      

# use Qwen 2.5 Coder 14B + 0.5B draft for speculative decoding
llama-server --fim-qwen-14b-spec                     
```

### Manually:

```bash
# qwen2.5-coder-1.5b
llama-server \
    --hf-repo ggerganov/Qwen2.5-Coder-1.5B-Q8_0-GGUF \
    --hf-file qwen2.5-coder-1.5b-q8_0.gguf \
    --port 8012 \
    --n-gpu-layers 99 --flash-attn \
    --ubatch-size 512 --batch-size 1024 \
    --defrag-thold 0.1 \
    --cache-reuse 256

# qwen2.5-coder-7b
llama-server \
    --hf-repo ggml-org/Qwen2.5-Coder-7B-Q8_0-GGUF \
    --hf-file qwen2.5-coder-7b-q8_0.gguf \
    --port 8012 \
    --n-gpu-layers 99 --flash-attn \
    --ubatch-size 512 --batch-size 1024 \
    --defrag-thold 0.1 \
    --cache-reuse 256
```


# WIP: python script

```bash
./scripts/serve_model.py --help

./scripts/serve_model.py --model-file ./models/qwen2.5-coder-1.5b-instruct-q8_0.gguf
```

```bash
python3 -m llama_cpp.server --config_file llama-cpp-python-server.config.json
```

