"""
Command-line interface for the dotfiles engine.
"""

import argparse
import sys
from pathlib import Path

from .commands import (
    gitconfig,
    graph,
    install,
    status,
    symlinks,
    symlinks_migrate,
    symlinks_rollback,
    uninstall,
)
from .commands import (
    list as list_cmd,
)
from .console import Theme, get_console, init


def _setup_console(args: argparse.Namespace) -> None:
    theme = Theme()
    init(
        theme=theme,
        use_colors=True,
        verbose=args.verbose,
    )


def main() -> None:
    parser = argparse.ArgumentParser(
        prog="dotfiles",
        description="Manage dotfiles with dependency resolution",
    )
    parser.add_argument(
        "--modules-dir",
        default="./modules",
        help="Modules directory",
    )
    parser.add_argument(
        "--state-dir",
        default="./state",
        help="State directory",
    )
    parser.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        help="Verbose output",
    )

    subparsers = parser.add_subparsers(dest="command", required=True)

    install.add_parser(subparsers)
    status.add_parser(subparsers)
    list_cmd.add_parser(subparsers)
    graph.add_parser(subparsers)
    uninstall.add_parser(subparsers)
    symlinks.add_parser(subparsers)
    symlinks_migrate.add_parser(subparsers)
    symlinks_rollback.add_parser(subparsers)
    gitconfig.add_parser(subparsers)

    args = parser.parse_args()

    _setup_console(args)

    Path(args.state_dir).mkdir(parents=True, exist_ok=True)

    try:
        args.func(args)
    except KeyboardInterrupt:
        console = get_console()
        console.warning("Cancelled")
        sys.exit(130)
    except Exception as e:
        console = get_console()
        console.error(f"Unexpected error: {e}")
        import traceback

        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
