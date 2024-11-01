export OLLAMA_DEBUG="" #              Show additional debug information (e.g. OLLAMA_DEBUG=1)
export OLLAMA_HOST="" #               IP Address for the ollama server (default 127.0.0.1:11434)
export OLLAMA_KEEP_ALIVE="" #         The duration that models stay loaded in memory (default "5m")
export OLLAMA_MAX_LOADED_MODELS="1" #  Maximum number of loaded models per GPU
export OLLAMA_MAX_QUEUE="4" #          Maximum number of queued requests
export OLLAMA_MODELS="" #             The path to the models directory
export OLLAMA_NUM_PARALLEL="8" #       Maximum number of parallel requests
export OLLAMA_NOPRUNE="" #            Do not prune model blobs on startup
export OLLAMA_ORIGINS="" #            A comma separated list of allowed origins
export OLLAMA_SCHED_SPREAD="" #       Always schedule model across all GPUs
export OLLAMA_TMPDIR="" #             Location for temporary files
export OLLAMA_FLASH_ATTENTION="1" #    Enabled flash attention
export OLLAMA_LLM_LIBRARY="" #        Set LLM library to bypass autodetection
export OLLAMA_GPU_OVERHEAD="" #       Reserve a portion of VRAM per GPU (bytes)
export OLLAMA_LOAD_TIMEOUT="" #       How long to allow model loads to stall before giving up (default "5m")

if [[ $(uname) == "Darwin" ]]
then
    # NOTE: `launchctl setenv` sets environment variables for apps launched from Spotlight

    launchctl setenv OLLAMA_DEBUG "$OLLAMA_DEBUG" #              Show additional debug information (e.g. OLLAMA_DEBUG=1)
    launchctl setenv OLLAMA_HOST "$OLLAMA_HOST" #               IP Address for the ollama server (default 127.0.0.1:11434)
    launchctl setenv OLLAMA_KEEP_ALIVE "$OLLAMA_KEEP_ALIVE" #         The duration that models stay loaded in memory (default "5m")
    launchctl setenv OLLAMA_MAX_LOADED_MODELS "$OLLAMA_MAX_LOADED_MODELS" #  Maximum number of loaded models per GPU
    launchctl setenv OLLAMA_MAX_QUEUE "$OLLAMA_MAX_QUEUE" #          Maximum number of queued requests
    launchctl setenv OLLAMA_MODELS "$OLLAMA_MODELS" #             The path to the models directory
    launchctl setenv OLLAMA_NUM_PARALLEL "$OLLAMA_NUM_PARALLEL" #       Maximum number of parallel requests
    launchctl setenv OLLAMA_NOPRUNE "$OLLAMA_NOPRUNE" #            Do not prune model blobs on startup
    launchctl setenv OLLAMA_ORIGINS "$OLLAMA_ORIGINS" #            A comma separated list of allowed origins
    launchctl setenv OLLAMA_SCHED_SPREAD "$OLLAMA_SCHED_SPREAD" #       Always schedule model across all GPUs
    launchctl setenv OLLAMA_TMPDIR "$OLLAMA_TMPDIR" #             Location for temporary files
    launchctl setenv OLLAMA_FLASH_ATTENTION "$OLLAMA_FLASH_ATTENTION" #    Enabled flash attention
    launchctl setenv OLLAMA_LLM_LIBRARY "$OLLAMA_LLM_LIBRARY" #        Set LLM library to bypass autodetection
    launchctl setenv OLLAMA_GPU_OVERHEAD "$OLLAMA_GPU_OVERHEAD" #       Reserve a portion of VRAM per GPU (bytes)
    launchctl setenv OLLAMA_LOAD_TIMEOUT "$OLLAMA_LOAD_TIMEOUT" #       How long to allow model loads to stall before giving up (default "5m")
fi

