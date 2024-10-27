import logging

def configure_logging() -> None:
    # ANSI color codes
    # ANSI_DARK_GRAY = "\033[1;30m"
    ANSI_LIGHT_GRAY = "\033[0;37m"
    ANSI_RESET = "\033[0m"  # Reset to default color
    logging.basicConfig(
        level=logging.INFO,
        format=f"{ANSI_LIGHT_GRAY}[%(name)s %(asctime)s] %(levelname)s:{ANSI_RESET} %(message)s",
    )


