import logging
import os

import log

logger = logging.getLogger(__name__)


def serve_app(host: str, port: int) -> None:
    import uvicorn

    logger.info(f"Running app on http://{host}:{port}")
    uvicorn.run("server:app", host=host, port=port)  # , workers=2)


def main() -> None:
    log.configure_logging()

    host = os.environ.get("COMPLETION_SERVER_HOST", "localhost")
    port = int(os.environ.get("COMPLETION_SERVER_PORT", 9000))

    serve_app(host=host, port=port)


if __name__ == "__main__":
    main()
