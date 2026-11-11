"""Status command."""

import argparse
from pathlib import Path

from ..console import get_console
from ..health import HealthChecker
from ..module import discover_modules, get_current_platform
from ..requirements import RequirementChecker
from ..state import StateManager


def run(args: argparse.Namespace) -> None:
    """Handle status command."""
    console = get_console()
    modules_dir = Path(args.modules_dir)
    state_dir = Path(args.state_dir)

    modules = discover_modules(modules_dir) if modules_dir.exists() else {}
    state = StateManager(state_dir)
    installed = set(state.get_installed())

    if args.health:
        current_platform = get_current_platform()
        checker = HealthChecker(state)
        req_checker = RequirementChecker()

        if args.module:
            if args.module not in modules:
                console.error(f"Module not found: {args.module}")
                return
            to_check = {args.module: modules[args.module]}
        else:
            to_check = {name: mod for name, mod in modules.items() if name in installed}

        console.heading("Health Check")
        console.rule()

        results = checker.check_all(to_check, current_platform)

        for name in sorted(results.keys()):
            result = results[name]
            module = to_check[name]

            if result.status.value == "ok":
                console.check(f"{name}: {result.message}")
            elif result.status.value == "warning":
                console.warn(f"{name}: {result.message}")
            elif result.status.value == "error":
                console.cross(f"{name}: {result.message}")
            else:
                console.print(f"  ? {name}: {result.message}")

            console.print(f"    {module.description}")

            unsatisfied = req_checker.get_unsatisfied(module)
            if unsatisfied:
                console.print("    Requirements:")
                for check in unsatisfied:
                    console.cross(f"      {check.message}")

            if result.output:
                output_lines = result.output.split("\n")[:3]
                for line in output_lines:
                    console.print(f"    | {line}")
        return

    console.heading("Module Status")
    console.rule()

    if not modules:
        console.info("No modules discovered")
        return

    for name in sorted(modules.keys()):
        module = modules[name]
        platforms = ", ".join(p.name.lower() for p in module.platforms) or "any"

        if name in installed:
            console.check(f"{name} [{platforms}]")
        else:
            console.print(f"  {name} [{platforms}]")
        console.print(f"    {module.description}")

    console.print("")
    if installed:
        console.key_value("Installed", f"{len(installed)} modules")
    else:
        console.info("No modules installed")


def add_parser(subparsers) -> argparse.ArgumentParser:
    parser = subparsers.add_parser("status", help="Show installation status")
    parser.add_argument("--health", "-H", action="store_true", help="Include health check results")
    parser.add_argument("module", nargs="?", help="Specific module to check")
    parser.set_defaults(func=run)
    return parser
