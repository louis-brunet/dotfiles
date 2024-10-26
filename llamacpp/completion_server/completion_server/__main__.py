import logging
import os

logger = logging.getLogger(__name__)


def configure_logging() -> None:
    # ANSI color codes
    # ANSI_DARK_GRAY = "\033[1;30m"
    ANSI_LIGHT_GRAY = "\033[0;37m"
    ANSI_RESET = "\033[0m"  # Reset to default color
    logging.basicConfig(
        level=logging.INFO,
        format=f"{ANSI_LIGHT_GRAY}[%(name)s %(asctime)s] %(levelname)s:{ANSI_RESET} %(message)s",
    )


def serve_app(host: str, port: int) -> None:
    import uvicorn

    logger.info(f"Running app on http://{host}:{port}")
    uvicorn.run("server:app", host=host, port=port)  # , workers=2)


def main() -> None:
    configure_logging()
    host = os.environ.get("HOST", "localhost")
    port = int(os.environ.get("PORT", 9000))

    serve_app(host=host, port=port)


if __name__ == "__main__":
    main()
