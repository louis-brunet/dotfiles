"""
Symlink management for the dotfiles engine.

This module provides:
- SymlinkMigrator: migrate symlinks from old to new paths
- SymlinkVerifier: verify symlink targets exist
- Backup/restore functionality
"""

import logging
import shutil
from dataclasses import dataclass
from pathlib import Path

import tomli
import tomli_w

logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class SymlinkEntry:
    """Represents a single symlink entry."""

    target: str  # e.g., ~/.zshrc
    source: str  # e.g., /home/louis/code/dotfiles/zsh/zshrc


@dataclass(frozen=True)
class SymlinkDiff:
    """Represents a change to a symlink."""

    target: str
    old_source: str | None
    new_source: str | None
    action: str  # "keep", "update", "add", "remove"


class SymlinkManager:
    """Manages symlink operations for migration."""

    def __init__(self, dotfiles_root: Path) -> None:
        self.dotfiles_root = dotfiles_root
        self.lock_file = dotfiles_root / "symlonk-lock.toml"
        self.backup_file = dotfiles_root / "symlonk-lock.toml.backup"

    def load_lock_file(self) -> dict[str, SymlinkEntry]:
        """Load current symlonk-lock.toml."""
        if not self.lock_file.exists():
            return {}

        with open(self.lock_file, "rb") as f:
            data = tomli.load(f)

        symlinks = {}
        for target, source in data.get("symlinks", {}).items():
            symlinks[target] = SymlinkEntry(target=target, source=source)

        return symlinks

    def save_lock_file(self, entries: dict[str, SymlinkEntry]) -> None:
        """Save symlink entries to lock file."""
        data = {"symlinks": {entry.target: entry.source for entry in entries.values()}}

        temp = self.lock_file.with_suffix(".tmp")
        with open(temp, "wb") as f:
            tomli_w.dump(data, f)

        temp.replace(self.lock_file)

    def backup(self) -> None:
        """Create backup of current lock file."""
        if self.lock_file.exists():
            shutil.copy2(self.lock_file, self.backup_file)
            logger.info(f"Backed up symlonk-lock.toml to {self.backup_file}")

    def restore(self) -> bool:
        """Restore from backup. Returns True if successful."""
        if not self.backup_file.exists():
            logger.error("No backup file found")
            return False

        shutil.copy2(self.backup_file, self.lock_file)
        logger.info("Restored symlonk-lock.toml from backup")
        return True

    def compute_migration_diff(self) -> list[SymlinkDiff]:
        """Compute what would change during migration."""
        current = self.load_lock_file()

        diffs: list[SymlinkDiff] = []

        # Old path mappings: /dotfiles/zsh/ → /dotfiles/modules/zsh/
        old_to_new = self._get_path_mappings()

        for target, entry in current.items():
            old_source = entry.source
            new_source = self._map_source(old_source, old_to_new)

            if new_source:
                # Check if source changed
                if old_source != new_source:
                    diffs.append(
                        SymlinkDiff(
                            target=target,
                            old_source=old_source,
                            new_source=new_source,
                            action="update",
                        )
                    )
                else:
                    diffs.append(
                        SymlinkDiff(
                            target=target,
                            old_source=old_source,
                            new_source=new_source,
                            action="keep",
                        )
                    )
            else:
                # Source doesn't match any mapping pattern
                diffs.append(
                    SymlinkDiff(
                        target=target,
                        old_source=old_source,
                        new_source=None,
                        action="keep",
                    )
                )

        return diffs

    def _get_path_mappings(self) -> dict[str, str]:
        """Get mapping of old paths to new paths."""
        root = str(self.dotfiles_root)

        # Directories that have been migrated to modules/
        return {
            f"{root}/zsh": f"{root}/modules/zsh",
            f"{root}/git": f"{root}/modules/git",
            f"{root}/nvim": f"{root}/modules/nvim",
            f"{root}/wezterm": f"{root}/modules/wezterm",
            f"{root}/tmux": f"{root}/modules/tmux",
            f"{root}/i3": f"{root}/modules/i3",
            f"{root}/python": f"{root}/modules/python",
            f"{root}/opencode": f"{root}/modules/opencode",
            f"{root}/qmk": f"{root}/modules/qmk",
            f"{root}/jetbrains": f"{root}/modules/jetbrains",
            f"{root}/vscode": f"{root}/modules/vscode",
            f"{root}/windows": f"{root}/modules/windows",
            f"{root}/aws": f"{root}/modules/aws",
            f"{root}/docker": f"{root}/modules/docker",
            f"{root}/eza": f"{root}/modules/eza",
            f"{root}/gcp": f"{root}/modules/gcp",
            f"{root}/llamacpp": f"{root}/modules/llamacpp",
            f"{root}/llm-tools": f"{root}/modules/llm-tools",
            f"{root}/macos": f"{root}/modules/macos",
            f"{root}/mysql": f"{root}/modules/mysql",
            f"{root}/node": f"{root}/modules/node",
            f"{root}/ollama": f"{root}/modules/ollama",
            f"{root}/rust": f"{root}/modules/rust",
            f"{root}/shell": f"{root}/modules/shell",
            f"{root}/snowflake": f"{root}/modules/snowflake",
            f"{root}/system": f"{root}/modules/system",
            f"{root}/terraform": f"{root}/modules/terraform",
            f"{root}/angular": f"{root}/modules/angular",
        }

    def _map_source(self, source: str, mappings: dict[str, str]) -> str | None:
        """Map an old source path to a new one."""
        for old_prefix, new_prefix in mappings.items():
            if source.startswith(old_prefix):
                return source.replace(old_prefix, new_prefix, 1)
        return None

    def verify_targets(self, diffs: list[SymlinkDiff] | None = None) -> dict[str, bool]:
        """Verify all symlink targets exist. Returns dict of target -> exists."""
        if diffs is None:
            diffs = self.compute_migration_diff()

        results: dict[str, bool] = {}

        for diff in diffs:
            if diff.action == "keep" and diff.old_source:
                source = diff.old_source
            elif diff.new_source:
                source = diff.new_source
            else:
                continue

            # Expand ~ to home directory
            if source.startswith("~/"):
                source = str(Path.home() / source[2:])

            exists = Path(source).exists()
            results[diff.target] = exists
            if not exists:
                logger.warning(f"Target does not exist: {source}")

        return results

    def migrate(self, dry_run: bool = True) -> list[SymlinkDiff]:
        """Execute migration. Returns diff of changes."""
        diffs = self.compute_migration_diff()

        if dry_run:
            logger.info("DRY RUN - no changes made")
            return diffs

        # Backup first
        self.backup()

        # Apply changes
        current = self.load_lock_file()

        for diff in diffs:
            if diff.action == "update" and diff.new_source:
                current[diff.target] = SymlinkEntry(
                    target=diff.target,
                    source=diff.new_source,
                )

        self.save_lock_file(current)
        logger.info("Migration complete")

        return diffs


def create_manager(dotfiles_root: Path | str | None = None) -> SymlinkManager:
    """Create a SymlinkManager instance."""
    if dotfiles_root is None:
        # Default to parent of modules/
        dotfiles_root = Path(__file__).parent.parent
    else:
        dotfiles_root = Path(dotfiles_root)

    return SymlinkManager(dotfiles_root)
