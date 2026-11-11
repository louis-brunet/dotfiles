"""Symlinks rollback command."""

import argparse
import sys
from pathlib import Path

from ..console import get_console
from ..symlinks import SymlinkManager


def run(args: argparse.Namespace) -> None:
    """Rollback symlinks to previous state."""
    console = get_console()
    dotfiles_root = Path(args.dotfiles_root).resolve()
    manager = SymlinkManager(dotfiles_root)

    if args.dry_run:
        console.warning("DRY RUN - would rollback to backup")
        return

    if manager.restore():
        console.success("Rollback complete!")
    else:
        console.error("Rollback failed - no backup found")
        sys.exit(1)


def add_parser(subparsers) -> argparse.ArgumentParser:
    parser = subparsers.add_parser("symlinks-rollback", help="Rollback symlinks to backup")
    parser.add_argument("--dotfiles-root", default=".", help="Dotfiles root directory")
    parser.add_argument(
        "--dry-run", action="store_true", help="Show what would happen without making changes"
    )
    parser.set_defaults(func=run)
    return parser
