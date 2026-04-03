"""Symlinks command."""

import argparse
import shutil
import subprocess
import sys
from pathlib import Path

from ..console import get_console
from ..module import discover_modules


def run(args: argparse.Namespace) -> None:
    """Handle symlinks command."""
    console = get_console()
    modules_dir = Path(args.modules_dir)
    dotfiles_root = modules_dir.parent

    if not shutil.which("symlonk"):
        console.error("symlonk not found. Install from https://github.com/louis-brunet/symlonk")
        sys.exit(1)

    modules = discover_modules(modules_dir)
    symlonk_configs = []
    for name, module in modules.items():
        if module.has_symlonk_config:
            symlonk_configs.append(str(module.symlonk_config))

    if not symlonk_configs:
        console.info("No symlonk configs found in modules")
        return

    console.info(f"Found {len(symlonk_configs)} symlonk configs")

    cmd = ["symlonk", "create", "links"]
    cmd.extend(symlonk_configs)

    if args.verify:
        cmd.append("--verify")
    if args.prune:
        cmd.append("--prune")

    if args.dry_run:
        console.warning(f"DRY RUN - would run: {' '.join(cmd)}")
        return

    if args.yes:
        result = subprocess.run(
            cmd,
            cwd=dotfiles_root,
            input="y\n" * len(symlonk_configs),
            text=True,
        )
    else:
        result = subprocess.run(cmd, cwd=dotfiles_root)
    sys.exit(result.returncode)


def add_parser(subparsers) -> argparse.ArgumentParser:
    parser = subparsers.add_parser("symlinks", help="Manage symlinks via symlonk")
    parser.add_argument("--create", action="store_true", help="Create symlinks")
    parser.add_argument("--verify", action="store_true", help="Verify symlinks")
    parser.add_argument("--prune", action="store_true", help="Prune broken symlinks")
    parser.add_argument("--dry-run", action="store_true", help="Show what would happen")
    parser.add_argument(
        "-y", "--yes", action="store_true", help="Auto-accept prompts (answer yes to all)"
    )
    parser.set_defaults(func=run)
    return parser
