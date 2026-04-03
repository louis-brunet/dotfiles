"""Graph command."""

import argparse
import sys
from pathlib import Path

from ..console import get_console
from ..graph import DependencyGraph
from ..module import discover_modules


def run(args: argparse.Namespace) -> None:
    """Handle graph command."""
    console = get_console()
    modules_dir = Path(args.modules_dir)

    if not modules_dir.exists():
        console.error(f"Modules directory not found: {modules_dir}")
        sys.exit(1)

    modules = discover_modules(modules_dir)
    graph = DependencyGraph(modules=modules)

    if args.module:
        if args.module not in modules:
            console.error(f"Module not found: {args.module}")
            sys.exit(1)

        module = modules[args.module]
        deps = graph.get_dependencies(args.module)
        dependents = graph.get_dependents(args.module)

        console.heading(f"Module: {args.module}")
        console.key_value("Description", module.description)
        console.key_value("Dependencies", ", ".join(deps) or "none")
        console.key_value("Dependents", ", ".join(dependents) or "none")
    else:
        console.heading("Dependency Graph")
        console.rule()

        cycles = graph.detect_cycles()
        if cycles:
            console.warning("Cycles detected:")
            for cycle in cycles:
                console.print(f"  {' → '.join(cycle[:-1])} → {cycle[0]}")

        try:
            order = graph.topological_sort()
            console.key_value("Install order", " → ".join(order))
        except ValueError as e:
            console.error(f"Cannot determine order: {e}")

        console.subheading("Modules:")
        for name in sorted(modules.keys()):
            deps = modules[name].depends
            dep_str = f" ← {', '.join(deps)}" if deps else ""
            console.print(f"  {name}{dep_str}")


def add_parser(subparsers) -> argparse.ArgumentParser:
    parser = subparsers.add_parser("graph", help="Show dependency graph")
    parser.add_argument("module", nargs="?", help="Specific module")
    parser.set_defaults(func=run)
    return parser
