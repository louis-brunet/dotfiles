# Download model from HF
## Script
```bash
./scripts/download_model.py --help

# if no merge is needed
./scripts/download_model.py --hf-repo "Qwen/Qwen2.5-Coder-1.5B-Instruct-GGUF" --hf-files "qwen2.5-coder-1.5b-instruct-q8_0.gguf" --output-file-path "models/qwen2.5-coder-1.5b-instruct-q8_0.gguf"

# if merge is needed
./scripts/download_model.py --hf-repo "Qwen/Qwen2.5-Coder-7B-Instruct-GGUF" --hf-files "qwen2.5-coder-7b-instruct-q5_k_m*.gguf" --merge --output-file-path "models/qwen2.5-coder-7b-instruct-q5_k_m.gguf"
```

## Running for ggml-org/llama.vim plugin

```bash
llama-server \
    --hf-repo ggerganov/Qwen2.5-Coder-1.5B-Q8_0-GGUF \
    --hf-file qwen2.5-coder-1.5b-q8_0.gguf \
    --port 8012 -ngl 99 -fa -ub 512 -b 1024 -dt 0.1 \
    --cache-reuse 256
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
```bash
./scripts/serve_model.py --help

./scripts/serve_model.py --model-file ./models/qwen2.5-coder-1.5b-instruct-q8_0.gguf
```

```bash
python3 -m llama_cpp.server --config_file llama-cpp-python-server.config.json
```

