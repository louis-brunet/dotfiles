"""
Console output and logging for the dotfiles engine.

Provides:
- Styled console output with colors
- Structured logging levels
- Formatted tables and progress displays
"""

import sys
import time
from dataclasses import dataclass
from enum import Enum
from typing import Protocol


class Level(Enum):
    """Output levels."""

    DEBUG = "debug"
    INFO = "info"
    SUCCESS = "success"
    WARNING = "warning"
    ERROR = "error"
    PROGRESS = "progress"


class Color:
    """ANSI color codes."""

    RESET = "\033[0m"
    BOLD = "\033[1m"

    BLACK = "\033[30m"
    RED = "\033[31m"
    GREEN = "\033[32m"
    YELLOW = "\033[33m"
    BLUE = "\033[34m"
    MAGENTA = "\033[35m"
    CYAN = "\033[36m"
    WHITE = "\033[37m"

    BRIGHT_BLACK = "\033[90m"
    BRIGHT_RED = "\033[91m"
    BRIGHT_GREEN = "\033[92m"
    BRIGHT_YELLOW = "\033[93m"
    BRIGHT_BLUE = "\033[94m"
    BRIGHT_MAGENTA = "\033[95m"
    BRIGHT_CYAN = "\033[96m"
    BRIGHT_WHITE = "\033[97m"


@dataclass
class Theme:
    """Color theme for console output."""

    debug: str = Color.BRIGHT_BLACK
    info: str = Color.WHITE
    success: str = Color.BRIGHT_GREEN
    warning: str = Color.BRIGHT_YELLOW
    error: str = Color.BRIGHT_RED
    progress: str = Color.BRIGHT_CYAN

    prefix_debug: str = "DEBUG"
    prefix_info: str = "INFO"
    prefix_success: str = "OK"
    prefix_warning: str = "WARN"
    prefix_error: str = "FAIL"
    prefix_progress: str = "..."

    dim: str = Color.BRIGHT_BLACK

    heading: str = Color.BRIGHT_CYAN + Color.BOLD
    subheading: str = Color.BRIGHT_WHITE + Color.BOLD

    symbol_check: str = Color.BRIGHT_GREEN + "✓" + Color.RESET
    symbol_cross: str = Color.BRIGHT_RED + "✗" + Color.RESET
    symbol_warn: str = Color.BRIGHT_YELLOW + "⚠" + Color.RESET
    symbol_info: str = Color.BRIGHT_CYAN + "●" + Color.RESET
    symbol_arrow: str = Color.BRIGHT_BLACK + "→" + Color.RESET


DEFAULT_THEME = Theme()


class Output(Protocol):
    """Protocol for output destinations."""

    def write(self, text: str) -> None: ...
    def flush(self) -> None: ...


class Console:
    """
    Styled console output.

    Supports colors, structured output, and formatting.
    """

    def __init__(
        self,
        theme: Theme | None = None,
        out: Output | None = None,
        err: Output | None = None,
        use_colors: bool = True,
        verbose: bool = False,
    ) -> None:
        self.theme = theme or DEFAULT_THEME
        self.out = out or sys.stdout
        self.err = err or sys.stderr
        self.use_colors = use_colors and sys.stdout.isatty()
        self.verbose = verbose
        self._indent = 0

    def _colorize(self, text: str, color: str) -> str:
        """Apply color to text if colors are enabled."""
        if self.use_colors:
            return f"{color}{text}{Color.RESET}"
        return text

    def _prefix(self, level: Level) -> str:
        """Get styled prefix for level."""
        theme = self.theme
        color = getattr(theme, level.value)
        prefix = getattr(theme, f"prefix_{level.value}")
        return self._colorize(f"[{prefix}]", color)

    def debug(self, message: str) -> None:
        """Log debug message."""
        if self.verbose:
            self._print(Level.DEBUG, message)

    def info(self, message: str) -> None:
        """Log info message."""
        self._print(Level.INFO, message)

    def success(self, message: str) -> None:
        """Log success message."""
        self._print(Level.SUCCESS, message)

    def warning(self, message: str) -> None:
        """Log warning message."""
        self._print(Level.WARNING, message)

    def error(self, message: str) -> None:
        """Log error message."""
        self._print(Level.ERROR, message)

    def _print(self, level: Level, message: str) -> None:
        """Print a message with level prefix."""
        prefix = self._prefix(level)
        indent = "  " * self._indent
        self.out.write(f"{indent}{prefix} {message}\n")
        self.out.flush()

    def print(self, message: str) -> None:
        """Print raw message without prefix."""
        indent = "  " * self._indent
        self.out.write(f"{indent}{message}\n")
        self.out.flush()

    def print_inline(self, message: str) -> None:
        """Print without trailing newline (for prompts)."""
        indent = "  " * self._indent
        self.out.write(f"{indent}{message}")
        self.out.flush()

    def heading(self, text: str) -> None:
        """Print a heading."""
        if self.use_colors:
            self.out.write(f"\n{self.theme.heading}{text}{Color.RESET}\n")
        else:
            self.out.write(f"\n{text}\n")
        self.out.flush()

    def subheading(self, text: str) -> None:
        """Print a subheading."""
        if self.use_colors:
            self.out.write(f"{self.theme.subheading}{text}{Color.RESET}\n")
        else:
            self.out.write(f"{text}\n")
        self.out.flush()

    def rule(self, char: str = "─", width: int = 60) -> None:
        """Print a horizontal rule."""
        self.out.write(char * width + "\n")
        self.out.flush()

    def indent(self) -> None:
        """Increase indentation."""
        self._indent += 1

    def dedent(self) -> None:
        """Decrease indentation."""
        self._indent = max(0, self._indent - 1)

    def with_indent(self) -> "Console":
        """Return a new Console with increased indent."""
        newConsole = Console(
            theme=self.theme,
            out=self.out,
            err=self.err,
            use_colors=self.use_colors,
            verbose=self.verbose,
        )
        newConsole._indent = self._indent + 1
        return newConsole

    def check(self, message: str) -> None:
        """Print a checkmark with message."""
        symbol = self._colorize(self.theme.symbol_check, self.theme.success)
        indent = "  " * self._indent
        self.out.write(f"{indent}{symbol} {message}\n")
        self.out.flush()

    def cross(self, message: str) -> None:
        """Print a cross with message."""
        symbol = self._colorize(self.theme.symbol_cross, self.theme.error)
        indent = "  " * self._indent
        self.out.write(f"{indent}{symbol} {message}\n")
        self.out.flush()

    def warn(self, message: str) -> None:
        """Print a warning symbol with message."""
        symbol = self._colorize(self.theme.symbol_warn, self.theme.warning)
        indent = "  " * self._indent
        self.out.write(f"{indent}{symbol} {message}\n")
        self.out.flush()

    def info_sym(self, message: str) -> None:
        """Print an info symbol with message."""
        symbol = self._colorize(self.theme.symbol_info, self.theme.progress)
        indent = "  " * self._indent
        self.out.write(f"{indent}{symbol} {message}\n")
        self.out.flush()

    def table(self, rows: list[list[str]], headers: list[str] | None = None) -> None:
        """Print a table."""
        if not rows:
            return

        col_widths = [
            max(len(str(row[i])) for row in ([headers] if headers else []) + rows)
            for i in range(len(rows[0]))
        ]

        def format_row(row: list[str]) -> str:
            return "  " + "  ".join(str(cell).ljust(width) for cell, width in zip(row, col_widths))

        if headers:
            self.print(format_row(headers))
            self.rule("─", sum(col_widths) + len(col_widths) * 2)

        for row in rows:
            self.print(format_row(row))

    def list_items(self, items: list[str], symbol: str | None = None) -> None:
        """Print a list of items."""
        for item in items:
            if symbol:
                self.print(f"{symbol} {item}")
            else:
                self.print(f"  • {item}")

    def key_value(self, key: str, value: str) -> None:
        """Print a key-value pair."""
        dim = self.theme.dim
        key_str = self._colorize(f"{key}:", dim)
        self.print(f"{key_str} {value}")

    def progress_start(self, message: str) -> "_ProgressTracker":
        """Start a progress tracker."""
        return _ProgressTracker(self, message)

    def confirm(self, message: str, default: bool = False) -> bool:
        """Ask for confirmation."""
        suffix = " [Y/n] " if default else " [y/N] "
        suffix += ": "

        while True:
            self.out.write(f"{message}{suffix}")
            self.out.flush()

            try:
                response = input().strip().lower()
            except EOFError:
                return default

            if not response:
                return default

            if response in ("y", "yes"):
                return True
            if response in ("n", "no"):
                return False


class _ProgressTracker:
    """Progress tracker for operations."""

    def __init__(self, console: Console, message: str) -> None:
        self.console = console
        self.message = message
        self.start = time.perf_counter()
        self._printed = False
        self._print()

    def _print(self) -> None:
        """Print progress message."""
        self.console.out.write(f"  ... {self.message}...")
        self.console.out.flush()
        self._printed = True

    def update(self, message: str) -> None:
        """Update progress message."""
        if self._printed:
            self.console.out.write("\r")
        self.message = message
        self._print()

    def success(self, message: str | None = None) -> None:
        """Mark as success."""
        msg = message or self.message
        duration = time.perf_counter() - self.start

        if self._printed:
            self.console.out.write("\r")

        symbol = self.console.theme.symbol_check
        dim = self.console.theme.dim
        time_str = f"({duration:.2f}s)"

        self.console.out.write(f"  {symbol} {msg} {dim}{time_str}{Color.RESET}\n")
        self.console.out.flush()

    def error(self, message: str | None = None) -> None:
        """Mark as error."""
        msg = message or self.message
        duration = time.perf_counter() - self.start

        if self._printed:
            self.console.out.write("\r")

        symbol = self.console.theme.symbol_cross
        dim = self.console.theme.dim
        time_str = f"({duration:.2f}s)"

        self.console.out.write(f"  {symbol} {msg} {dim}{time_str}{Color.RESET}\n")
        self.console.out.flush()


_global: Console | None = None


def get_console() -> Console:
    """Get the global console instance."""
    global _global
    if _global is None:
        _global = Console()
    return _global


def set_console(console: Console) -> None:
    """Set the global console instance."""
    global _global
    _global = console


def init(
    theme: Theme | None = None,
    use_colors: bool = True,
    verbose: bool = False,
    out: Output | None = None,
    err: Output | None = None,
) -> Console:
    """Initialize the global console."""
    global _global
    _global = Console(
        theme=theme,
        use_colors=use_colors,
        verbose=verbose,
        out=out,
        err=err,
    )
    return _global
