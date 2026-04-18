"""Install command."""

import argparse
import sys
from pathlib import Path

from ..console import get_console
from ..executor import Executor
from ..graph import DependencyGraph
from ..module import discover_modules, get_current_platform
from ..requirements import RequirementChecker
from ..state import StateManager


def run(args: argparse.Namespace) -> None:
    """Handle install command."""
    console = get_console()
    modules_dir = Path(args.modules_dir)
    state_dir = Path(args.state_dir)

    modules = discover_modules(modules_dir)
    if not modules:
        console.error(f"No modules found in {modules_dir}")
        sys.exit(1)

    console.info(f"Discovered {len(modules)} modules")

    graph = DependencyGraph(modules=modules)

    if args.modules:
        targets = list(args.modules)
        unknown = [t for t in targets if t not in modules]
        if unknown:
            console.error(f"Unknown modules: {unknown}")
            sys.exit(1)
        console.info(f"Installing: {targets}")
    else:
        targets = list(modules.keys())
        console.info("Installing all modules")

    current_platform = get_current_platform()
    targets = [t for t in targets if modules[t].is_available_on_platform(current_platform)]
    console.info(f"Filtered by platform ({current_platform.name}): {len(targets)} modules")

    state = StateManager(state_dir)
    installed = set(state.get_installed())

    for target in targets:
        module = modules[target]
        for conflict in module.conflicts:
            if conflict in installed:
                console.error(
                    f"Cannot install {target}: conflicts with installed module '{conflict}'"
                )
                sys.exit(1)

    if not args.force:
        targets = [t for t in targets if t not in installed]
        if not targets:
            console.success("All modules already installed")
            return
        console.info(f"Skipping already installed: {len(installed)} modules")

    try:
        order = graph.resolve_install_order(targets)
    except (KeyError, ValueError) as e:
        console.error(f"Dependency resolution failed: {e}")
        sys.exit(1)

    console.info(f"Installation order: {' → '.join(order)}")

    checker = RequirementChecker()

    for name in order:
        module = modules[name]
        unsatisfied = checker.get_unsatisfied(module)

        if unsatisfied:
            actually_unsatisfied = []
            for check in unsatisfied:
                if check.type == "command":
                    provided = False
                    for other_name in order:
                        if other_name == name:
                            continue
                        other_module = modules[other_name]
                        if check.name in other_module.provides:
                            provided = True
                            break

                    if not provided:
                        actually_unsatisfied.append(check)
                else:
                    actually_unsatisfied.append(check)

            if actually_unsatisfied:
                console.error(f"Cannot install {name}: missing requirements")
                for check in actually_unsatisfied:
                    console.error(f"  - {check.message}")
                if not args.ignore_requirements:
                    sys.exit(1)
                else:
                    console.warning("  (ignoring due to --ignore-requirements)")

    console.success("All requirements satisfied")

    if args.dry_run:
        console.warning("DRY RUN - would install:")
        state = StateManager(state_dir)
        for i, name in enumerate(order, 1):
            module = modules[name]
            status = "INSTALLED" if state.is_installed(name) else "PENDING"
            console.print(f"  {i}. [{status}] {name}: {module.description}")
        return

    state = StateManager(state_dir)
    executor = Executor(state)
    results = executor.execute_order(order, modules, force=args.force)

    succeeded = [n for n, r in results.items() if r.success]
    failed = [n for n, r in results.items() if not r.success]

    if failed:
        console.error(f"Failed: {failed}")
        sys.exit(1)

    console.success(f"Completed: {len(succeeded)} modules installed")


def add_parser(subparsers) -> argparse.ArgumentParser:
    parser = subparsers.add_parser("install", help="Install modules")
    parser.add_argument("modules", nargs="*", help="Modules to install")
    parser.add_argument("--dry-run", action="store_true", help="Show what would happen")
    parser.add_argument("--force", action="store_true", help="Reinstall if already installed")
    parser.add_argument(
        "--ignore-requirements", action="store_true", help="Ignore missing requirements"
    )
    parser.set_defaults(func=run)
    return parser
