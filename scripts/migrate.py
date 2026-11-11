#!/usr/bin/env python3
"""Interactive migration script for dotfiles engine."""

import subprocess
import sys
from pathlib import Path


def run_cmd(cmd: list[str], show_output: bool = True) -> subprocess.CompletedProcess:
    """Run a command and return result."""
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0 and show_output:
        print(f"\n[ERROR] Command failed: {' '.join(cmd)}")
        if result.stdout:
            print(f"[STDOUT]\n{result.stdout}")
        if result.stderr:
            print(f"[STDERR]\n{result.stderr}")
    return result


def confirm(prompt: str, default: bool = False) -> bool:
    """Ask for confirmation."""
    suffix = " [Y/n]: " if default else " [y/N]: "
    while True:
        response = input(prompt + suffix).strip().lower()
        if not response:
            return default
        if response in ("y", "yes"):
            return True
        if response in ("n", "no"):
            return False
        print("Please answer y or n")


def section(title: str) -> None:
    """Print a section header."""
    print(f"\n{'=' * 60}")
    print(f"  {title}")
    print("=" * 60)


def main() -> None:
    print("""
╔══════════════════════════════════════════════════════════════╗
║         Dotfiles Engine Migration Script                   ║
║                                                          ║
║  This script will guide you through migrating your       ║
║  dotfiles to use the new engine with symlonk.            ║
╚══════════════════════════════════════════════════════════════╝
""")

    print("This script will NOT make any changes without your confirmation.")
    print("You can press Ctrl+C to abort at any time.\n")

    if not confirm("Start migration?", default=True):
        print("Aborted.")
        sys.exit(0)

    section("Step 1: Backup Current State")

    print("\nBacking up symlonk-lock.toml...")
    lock_file = Path("symlonk-lock.toml")
    if lock_file.exists():
        backup = Path("symlonk-lock.toml.backup")
        run_cmd(["cp", str(lock_file), str(backup)])
        print(f"  Backed up to: {backup}")

    if Path("state").exists():
        run_cmd(["cp", "-r", "state", "state.backup"])
        print("  Backed up state/ directory")

    print("\n✓ Backup complete")

    section("Step 2: Check Module Discovery")

    print("\nDiscovering modules...")
    result = run_cmd(["uv", "run", "python", "-m", "engine.cli", "list"])
    if result.returncode != 0:
        print("ERROR: Failed to list modules")
        print(f"[STDERR]: {result.stderr}")
        sys.exit(1)
    print(result.stdout)

    section("Step 3: Check Current Status")

    print("\nCurrent installation status...")
    result = run_cmd(["uv", "run", "python", "-m", "engine.cli", "status"])
    print(result.stdout)

    section("Step 4: Symlink Migration - Preview")

    print("\nShowing symlink migration diff...")
    result = run_cmd(["uv", "run", "python", "-m", "engine.cli", "symlinks-migrate", "--diff"])
    print(result.stdout)

    section("Step 5: Verify Symlink Targets")

    print("\nVerifying all symlink targets exist...")
    result = run_cmd(
        ["uv", "run", "python", "-m", "engine.cli", "symlinks-migrate", "--verify-targets"]
    )
    print(result.stdout)

    if result.returncode != 0:
        print("\n⚠️  WARNING: Some targets don't exist!")
        if not confirm("Continue anyway?", default=False):
            print("Aborted. Fix target issues before continuing.")
            sys.exit(1)

    section("Step 6: Dry Run - Install")

    print("\nDry-run install (preview only)...")
    result = run_cmd(["uv", "run", "python", "-m", "engine.cli", "install", "--dry-run"])
    print(result.stdout)

    section("Migration Summary")

    print("""
The following will happen:
  1. Backup (✓ done)
  2. Run module install scripts
  3. Migrate symlink lock file (update paths)
  4. Create new symlinks via symlonk
  5. Verify symlinks

This will NOT:
  - Delete your existing dotfiles/ directory contents
  - Remove any system packages
""")

    if not confirm("\nProceed with migration?", default=False):
        print("Aborted.")
        sys.exit(0)

    section("Step 7: Run Install")

    print("\nInstalling modules...")
    result = run_cmd(["uv", "run", "python", "-m", "engine.cli", "install"])

    print(result.stdout)

    if result.returncode != 0:
        print(f"\n⚠️  ERROR: Installation failed (exit code: {result.returncode})")
        if result.stdout:
            print(f"[STDOUT]\n{result.stdout}")
        if result.stderr:
            print(f"[STDERR]\n{result.stderr}")
        print("\nThis could mean:")
        print("  - A module has no install script for your platform")
        print("  - An install script failed")
        print("  - Requirements are not satisfied")
        if not confirm("Continue anyway?", default=False):
            print("Aborted. Check errors above.")
            sys.exit(1)
        print("\nContinuing with migration despite errors...")

    section("Step 8: Migrate Symlinks and Create")

    print("\nMigrating symlinks and creating new ones...")
    result = run_cmd(
        ["uv", "run", "python", "-m", "engine.cli", "symlinks-migrate", "--create", "--verify"]
    )

    print(result.stdout)

    if result.returncode != 0:
        print(f"\n⚠️  WARNING: symlinks returned exit code: {result.returncode}")
        if result.stderr:
            print(f"[STDERR]: {result.stderr}")
        if not confirm("Continue?", default=False):
            print("You can verify manually with: dotfiles symlinks --verify")

    section("Step 9: Final Verification")

    print("\nFinal status check...")
    result = run_cmd(["uv", "run", "python", "-m", "engine.cli", "status"])
    print(result.stdout)

    print("\nHealth check...")
    result = run_cmd(["uv", "run", "python", "-m", "engine.cli", "status", "--health"])
    print(result.stdout)

    section("Migration Complete!")

    print("""
✓ Migration complete!

Next steps:
  - Verify your tools work: nvim, git, zsh, etc.
  - Check symlinks: ls -la ~/.gitconfig ~/.zshrc ~/.config/nvim
  - Test git config: git config --list

If something is wrong:
  - Rollback: dotfiles symlinks-rollback
  - Revert state: cp -r state.backup state
  - Check logs above for error messages
""")

    if confirm("Everything looks good?", default=True):
        print("\n🎉 All done! Enjoy your new dotfiles setup.")
    else:
        print("""
Manual verification steps:
  - Check tools: nvim --version, git --version, zsh --version
  - Check symlinks: ls -la ~/.gitconfig
  - Check git config: cat modules/git/gitconfig.local
  - Check failed modules: uv run python -m engine.cli status --health
""")


if __name__ == "__main__":
    main()
