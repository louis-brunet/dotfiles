"""List command."""

import argparse
import sys
from pathlib import Path

from ..console import get_console
from ..module import discover_modules, get_current_platform


def run(args: argparse.Namespace) -> None:
    """Handle list command."""
    console = get_console()
    modules_dir = Path(args.modules_dir)

    if not modules_dir.exists():
        console.error(f"Modules directory not found: {modules_dir}")
        sys.exit(1)

    modules = discover_modules(modules_dir)

    console.heading(f"Available Modules ({len(modules)})")
    console.rule()

    current = get_current_platform()

    for name in sorted(modules.keys()):
        module = modules[name]
        available = module.is_available_on_platform(current)
        platform_str = ", ".join(p.name.lower() for p in module.platforms) or "any"

        if available:
            console.check(f"{name}")
        else:
            console.cross(f"{name} (unavailable on {current.name})")

        console.print(f"    {module.description}")
        console.print(f"    Platforms: {platform_str}")

        if module.depends:
            console.print(f"    Dependencies: {', '.join(module.depends)}")
        console.print("")


def add_parser(subparsers) -> argparse.ArgumentParser:
    parser = subparsers.add_parser("list", help="List available modules")
    parser.set_defaults(func=run)
    return parser
