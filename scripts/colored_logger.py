import logging
from typing import TypedDict


class MissingRequiredPromptResult(Exception):
    def __init__(self, prompt: str) -> None:
        super().__init__(f"value is required for prompt '{prompt}'")


class ColorsDict(TypedDict):
    BLACK: str
    RED: str
    GREEN: str
    YELLOW: str
    BLUE: str
    MAGENTA: str
    CYAN: str
    WHITE: str
    BOLD_RED: str
    BOLD_GREEN: str
    BOLD_YELLOW: str
    BOLD_BLUE: str
    RESET: str


COLORS: ColorsDict = {
    "BLACK": "\033[0;30m",
    "RED": "\033[0;31m",
    "GREEN": "\033[0;32m",
    "YELLOW": "\033[0;33m",
    "BLUE": "\033[0;34m",
    "MAGENTA": "\033[0;35m",
    "CYAN": "\033[0;36m",
    "WHITE": "\033[0;37m",
    "BOLD_RED": "\033[1;31m",
    "BOLD_GREEN": "\033[1;32m",
    "BOLD_YELLOW": "\033[1;33m",
    "BOLD_BLUE": "\033[1;34m",
    "RESET": "\033[0m",
}


# Create a custom formatter with colored log levels
class ColoredFormatter(logging.Formatter):
    LEVEL_COLORS = {
        "DEBUG": COLORS["BLUE"],
        "INFO": COLORS["GREEN"],
        "WARNING": COLORS["YELLOW"],
        "ERROR": COLORS["RED"],
        "CRITICAL": COLORS["BOLD_RED"],
    }

    def format(self, record):
        # # Save the original format
        # orig_format = self._fmt

        # Apply the color for the log level name
        levelname = record.levelname
        if levelname in self.LEVEL_COLORS:
            colored_levelname = (
                f"{self.LEVEL_COLORS[levelname]}{levelname}{COLORS['RESET']}"
            )
            record.levelname = colored_levelname

        # Call the original formatter
        result = logging.Formatter.format(self, record)

        # Restore the original record.levelname
        record.levelname = levelname

        return result


# Set up the logger
def setup_colored_logging(
    level=logging.DEBUG, format="%(name)s %(levelname)s %(message)s"
):
    logger = logging.getLogger()
    logger.setLevel(level)

    # Remove existing handlers
    for handler in logger.handlers[:]:
        logger.removeHandler(handler)

    # Create console handler
    console_handler = logging.StreamHandler()
    console_handler.setLevel(level)

    # Create formatter
    formatter = ColoredFormatter(format)
    console_handler.setFormatter(formatter)

    # Add console handler to logger
    logger.addHandler(console_handler)
    return logger


def prompt(message: str) -> str | None:
    formatted_prompt=f"[{COLORS['BOLD_BLUE']}????{COLORS['RESET']}] {message} > "

    try:
        line = input(formatted_prompt)
    except EOFError:
        return None
    except KeyboardInterrupt:
        return None

    return line


def prompt_required(message: str, default: str | None = None) -> str:
    default_suffix = '' if default is None else f' [{default}]'
    result = prompt(f'{message}{default_suffix}')
    if result is None or result == "":
        if default is None:
            raise MissingRequiredPromptResult(message)
        result = default
    return result


def prompt_yes_no(message: str, default: bool | None = None) -> bool:
    options = "(y/n)"
    if default is True:
        options = "(Y/n)"
    elif default is False:
        options = "(y/N)"
    message_with_options = f"{message} {options}"
    if default is None:
        result = prompt_required(message_with_options)
    else:
        result = prompt(message_with_options)
        if result is None or result == "":
            result = "y" if default else "n"

    result_char = result[0].lower()
    if result_char == "y":
        return True
    if result_char == "n":
        return False
    raise MissingRequiredPromptResult(message_with_options)
