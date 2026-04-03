"""Uninstall command."""

import argparse
import subprocess
import sys
from pathlib import Path

from ..console import get_console
from ..executor import Executor
from ..graph import DependencyGraph
from ..module import discover_modules, get_current_platform
from ..state import StateManager


def run(args: argparse.Namespace) -> None:
    """Handle uninstall command."""
    console = get_console()
    modules_dir = Path(args.modules_dir)
    state_dir = Path(args.state_dir)
    dotfiles_root = modules_dir.parent

    if not args.module:
        console.error("Module name required for uninstall")
        console.print("Usage: dotfiles uninstall <module>")
        sys.exit(1)

    target = args.module

    modules = discover_modules(modules_dir)
    if target not in modules:
        console.error(f"Unknown module: {target}")
        sys.exit(1)

    module = modules[target]
    state = StateManager(state_dir)

    if not state.is_installed(target):
        console.error(f"Module '{target}' is not installed")
        sys.exit(1)

    current_platform = get_current_platform()

    uninstall_script = module.get_uninstall_script(current_platform)
    if not uninstall_script:
        console.error(f"No uninstall script for {current_platform.name} platform")
        sys.exit(1)

    console.info(f"Uninstalling {target}...")

    graph = DependencyGraph(modules=modules)
    dependents = graph.get_transitive_dependents(target)
    installed_dependents = [d for d in dependents if state.is_installed(d)]

    if installed_dependents and not args.force:
        console.error(
            f"Cannot uninstall {target}: installed modules depend on it: {installed_dependents}"
        )
        console.info("Use --force to uninstall anyway (may break dependent modules)")
        sys.exit(1)

    if args.dry_run:
        console.warning(f"DRY RUN - would uninstall {target}")
        if args.unlink:
            console.print("Would also unlink symlinks via symlonk")
        return

    executor = Executor(state)
    result = executor.execute(module, "uninstall")

    if result.success:
        state.remove(target)
        console.success(f"Uninstalled {target}")
    else:
        console.error(f"Uninstall failed: {result.message}")
        sys.exit(1)

    if args.unlink:
        console.info("Unlinking symlinks via symlonk...")
        import shutil

        if not shutil.which("symlonk"):
            console.warning("symlonk not found, skipping unlink")
        else:
            lock_file = dotfiles_root / "symlonk-lock.toml"
            if lock_file.exists():
                result = subprocess.run(
                    ["symlonk", "unlink", str(lock_file)],
                    cwd=dotfiles_root,
                )
                if result.returncode == 0:
                    console.success("Symlinks unlinked")
                else:
                    console.warning("Some symlinks may not have been removed")
            else:
                console.info("No symlonk-lock.toml found, skipping unlink")


def add_parser(subparsers) -> argparse.ArgumentParser:
    parser = subparsers.add_parser("uninstall", help="Uninstall a module")
    parser.add_argument("module", help="Module to uninstall")
    parser.add_argument(
        "--force", action="store_true", help="Force uninstall even if dependents exist"
    )
    parser.add_argument(
        "--unlink", "-u", action="store_true", help="Also unlink symlinks via symlonk"
    )
    parser.add_argument("--dry-run", action="store_true", help="Show what would happen")
    parser.set_defaults(func=run)
    return parser
