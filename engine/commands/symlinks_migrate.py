"""Symlinks migrate command."""

import argparse
import subprocess
import sys
from pathlib import Path

from ..console import get_console
from ..module import discover_modules
from ..symlinks import SymlinkManager


def run(args: argparse.Namespace) -> None:
    """Migrate symlinks from old to new paths."""
    console = get_console()
    dotfiles_root = Path(args.dotfiles_root).resolve()
    manager = SymlinkManager(dotfiles_root)

    if args.diff:
        diffs = manager.compute_migration_diff()
        console.heading("Symlink Migration Diff")
        console.rule()

        update_count = 0
        keep_count = 0

        for diff in diffs:
            if diff.action == "update":
                update_count += 1
                console.print(f"\n✱ {diff.target}")
                console.print(f"    OLD: {diff.old_source}")
                console.print(f"    NEW: {diff.new_source}")
            elif diff.action == "keep":
                keep_count += 1

        console.rule()
        console.key_value("Summary", f"{update_count} updates, {keep_count} unchanged")
        return

    if args.verify_targets:
        diffs = manager.compute_migration_diff()
        results = manager.verify_targets(diffs)

        console.heading("Symlink Target Verification")
        console.rule()

        missing = []
        for target, exists in results.items():
            if not exists:
                missing.append(target)
                console.cross(f"{target}")
            elif args.verbose:
                console.check(f"{target}")

        if missing:
            console.error(f"{len(missing)} target(s) not found!")
            sys.exit(1)
        else:
            console.success(f"All {len(results)} targets verified")
        return

    diffs = manager.compute_migration_diff()
    update_count = sum(1 for d in diffs if d.action == "update")

    if update_count == 0:
        console.info("No migrations needed - all symlinks already point to modules/")
        return

    console.info(f"Will update {update_count} symlink(s)")

    if args.dry_run:
        console.warning("DRY RUN - no changes made")
        console.print("Run without --dry-run to apply changes")
        if args.create:
            console.print("Would also create new symlinks via symlonk")
        return

    manager.migrate(dry_run=False)
    console.success("Migration complete!")

    if args.create:
        console.info("Creating symlinks via symlonk...")
        modules = discover_modules(dotfiles_root / "modules")
        symlonk_configs = []
        for name, module in modules.items():
            if module.has_symlonk_config:
                symlonk_configs.append(str(module.symlonk_config))

        cmd = ["symlonk", "create", "links"]
        cmd.extend(symlonk_configs)
        cmd.append("--verify")

        result = subprocess.run(cmd, cwd=dotfiles_root)
        sys.exit(result.returncode)

    if args.verify:
        console.info("Verifying symlinks...")
        result = subprocess.run(
            ["symlonk", "verify"],
            cwd=dotfiles_root,
        )
        sys.exit(result.returncode)


def add_parser(subparsers) -> argparse.ArgumentParser:
    parser = subparsers.add_parser("symlinks-migrate", help="Migrate symlinks to new paths")
    parser.add_argument("--dotfiles-root", default=".", help="Dotfiles root directory")
    parser.add_argument(
        "--dry-run", action="store_true", help="Show what would happen without making changes"
    )
    parser.add_argument("--verify", action="store_true", help="Verify symlinks after migration")
    parser.add_argument(
        "--create", "-c", action="store_true", help="Also create new symlinks via symlonk"
    )
    parser.add_argument(
        "--diff", action="store_true", help="Show migration diff without applying changes"
    )
    parser.add_argument(
        "--verify-targets", action="store_true", help="Verify all symlink targets exist"
    )
    parser.add_argument(
        "-v", "--verbose", action="store_true", help="Show all targets (not just missing)"
    )
    parser.set_defaults(func=run)
    return parser
