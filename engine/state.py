"""
State management for the dotfiles engine.

This module provides:
- StateManager: persists and queries installation state
- State data structures
- Atomic file operations
"""

import json
import logging
import time
from dataclasses import dataclass, field
from enum import Enum
from pathlib import Path
from typing import Self

logger = logging.getLogger(__name__)


class ModuleState(Enum):
    """Possible states for a module."""

    NOT_INSTALLED = "not_installed"
    INSTALLED = "installed"
    FAILED = "failed"
    UNINSTALLING = "uninstalling"


class HealthStatus(Enum):
    """Health check results."""

    OK = "ok"
    WARNING = "warning"
    ERROR = "error"
    UNKNOWN = "unknown"


@dataclass(frozen=True)
class ModuleStateRecord:
    """Immutable record of a module's installation state."""

    status: ModuleState
    version: str
    installed_at: float
    last_checked: float
    health: HealthStatus = HealthStatus.UNKNOWN
    depends_on: tuple[str, ...] = field(default_factory=tuple)

    @classmethod
    def from_dict(cls, data: dict) -> Self:
        return cls(
            status=ModuleState(data.get("status", "not_installed")),
            version=data.get("version", "1.0.0"),
            installed_at=data.get("installed_at", 0.0),
            last_checked=data.get("last_checked", 0.0),
            health=HealthStatus(data.get("health", "unknown")),
            depends_on=tuple(data.get("depends_on", [])),
        )

    def to_dict(self) -> dict:
        return {
            "status": self.status.value,
            "version": self.version,
            "installed_at": self.installed_at,
            "last_checked": self.last_checked,
            "health": self.health.value,
            "depends_on": list(self.depends_on),
        }


@dataclass(frozen=True)
class MigrationRecord:
    """Record of a migration/run."""

    id: str
    applied_at: float
    modules: tuple[str, ...]
    rollback_available: bool

    @classmethod
    def from_dict(cls, data: dict) -> Self:
        return cls(
            id=data["id"],
            applied_at=data["applied_at"],
            modules=tuple(data.get("modules", [])),
            rollback_available=data.get("rollback_available", True),
        )

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "applied_at": self.applied_at,
            "modules": list(self.modules),
            "rollback_available": self.rollback_available,
        }


@dataclass
class State:
    """Overall engine state."""

    version: int = 1
    last_updated: float = 0.0
    modules: dict[str, ModuleStateRecord] = field(default_factory=dict)
    migrations: list[MigrationRecord] = field(default_factory=list)


class StateManager:
    """
    Manages persistent installation state.

    State is stored in JSON files under state_dir:
    - state.json: current state
    - migrations/: individual migration records
    """

    def __init__(self, state_dir: Path | str) -> None:
        self.state_dir = Path(state_dir)
        self.state_file = self.state_dir / "state.json"
        self._state: State = self._load()

    def _load(self) -> State:
        """Load state from disk."""
        if not self.state_file.exists():
            logger.debug("No existing state file, creating new")
            return State()

        try:
            with open(self.state_file) as f:
                data = json.load(f)

            modules = {
                name: ModuleStateRecord.from_dict(record)
                for name, record in data.get("modules", {}).items()
            }

            migrations = [MigrationRecord.from_dict(m) for m in data.get("migrations", [])]

            return State(
                version=data.get("version", 1),
                last_updated=data.get("last_updated", 0.0),
                modules=modules,
                migrations=migrations,
            )
        except Exception as e:
            logger.warning(f"Failed to load state: {e}, creating new")
            return State()

    def _save(self) -> None:
        """Atomically save state to disk."""
        data = {
            "version": self._state.version,
            "last_updated": self._state.last_updated,
            "modules": {name: record.to_dict() for name, record in self._state.modules.items()},
            "migrations": [m.to_dict() for m in self._state.migrations],
        }

        # Atomic write
        temp = self.state_file.with_suffix(".tmp")
        try:
            self.state_dir.mkdir(parents=True, exist_ok=True)
            with open(temp, "w") as f:
                json.dump(data, f, indent=2)
            temp.replace(self.state_file)
        except Exception as e:
            logger.error(f"Failed to save state: {e}")
            if temp.exists():
                temp.unlink()
            raise

    def get(self, module_name: str) -> ModuleStateRecord | None:
        """Get state for a specific module."""
        return self._state.modules.get(module_name)

    def is_installed(self, module_name: str) -> bool:
        """Check if module is installed."""
        state = self.get(module_name)
        return state is not None and state.status == ModuleState.INSTALLED

    def get_installed(self) -> list[str]:
        """Get list of installed module names."""
        return [
            name
            for name, state in self._state.modules.items()
            if state.status == ModuleState.INSTALLED
        ]

    def set_installed(
        self,
        module_name: str,
        version: str,
        depends_on: list[str],
    ) -> None:
        """Mark a module as installed."""
        now = time.time()
        self._state.modules[module_name] = ModuleStateRecord(
            status=ModuleState.INSTALLED,
            version=version,
            installed_at=now,
            last_checked=now,
            health=HealthStatus.UNKNOWN,
            depends_on=tuple(depends_on),
        )
        self._state.last_updated = now
        self._save()

    def set_failed(self, module_name: str, version: str) -> None:
        """Mark a module as failed."""
        now = time.time()
        existing = self._state.modules.get(module_name)

        self._state.modules[module_name] = ModuleStateRecord(
            status=ModuleState.FAILED,
            version=version,
            installed_at=existing.installed_at if existing else 0.0,
            last_checked=now,
            health=HealthStatus.ERROR,
            depends_on=existing.depends_on if existing else (),
        )
        self._state.last_updated = now
        self._save()

    def remove(self, module_name: str) -> None:
        """Remove a module from state."""
        if module_name in self._state.modules:
            del self._state.modules[module_name]
            self._state.last_updated = time.time()
            self._save()

    def update_health(self, module_name: str, health: HealthStatus) -> None:
        """Update health status for a module."""
        if module_name not in self._state.modules:
            return

        existing = self._state.modules[module_name]
        self._state.modules[module_name] = ModuleStateRecord(
            status=existing.status,
            version=existing.version,
            installed_at=existing.installed_at,
            last_checked=time.time(),
            health=health,
            depends_on=existing.depends_on,
        )
        self._state.last_updated = time.time()
        self._save()

    def record_migration(
        self,
        migration_id: str,
        modules: list[str],
        rollback_available: bool = True,
    ) -> None:
        """Record a migration."""
        record = MigrationRecord(
            id=migration_id,
            applied_at=time.time(),
            modules=tuple(modules),
            rollback_available=rollback_available,
        )
        self._state.migrations.append(record)
        self._state.last_updated = time.time()
        self._save()

        # Also write individual migration file
        migration_file = self.state_dir / "migrations" / f"{migration_id}.json"
        migration_file.parent.mkdir(parents=True, exist_ok=True)
        with open(migration_file, "w") as f:
            json.dump(record.to_dict(), f, indent=2)

    def get_migrations(self) -> list[MigrationRecord]:
        """Get all migrations."""
        return list(self._state.migrations)

    def clear(self) -> None:
        """Clear all state (dangerous!)."""
        self._state = State()
        self._save()
        logger.warning("State cleared")
