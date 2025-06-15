## Run ollama

On Ubuntu (ROCM):

```bash
docker compose --file compose.yaml up
docker exec "$(docker ps --filter name=ollama-ollama-1 --quiet)" ollama --help
```

On macOS, it seems docker can't access the GPU. Install with brew instead:

```bash
./install_macos.sh
ollama --help
```


## Web UI

see [open-webui](https://github.com/open-webui/open-webui)

1. Enable web search

  ```bash
  # ... manually update the base image version in searxng/Dockerfile

  # define required environment variables
  cp searxng.env.example searxng.env
  vim searxng.env
  ```

2. Start the web UI and web search backend containers

  > [!IMPORTANT]
  >
  > On the initial run, `cap_drop: - ALL` MUST be commented out for the searxng
  > service in `webui.compose.yaml`.

  ```bash
  docker compose --file webui.compose.yaml up --build
  ```

3. Open [http://localhost:3000](http://localhost:3000)

