"""
Module representation and loading for the dotfiles engine.

This module provides:
- Module dataclass: represents a single installable module
- ModuleManifest: represents the parsed module.yaml contents
- Loading and discovery functions
- Validation functions
"""

import logging
from dataclasses import dataclass, field
from enum import Enum, auto
from pathlib import Path
from typing import Self

import yaml

logger = logging.getLogger(__name__)


class Platform(Enum):
    """Supported platforms."""

    LINUX = auto()
    MACOS = auto()
    WINDOWS = auto()

    @property
    def filename(self) -> str:
        """Filename component for platform-specific scripts."""
        return self.name.lower()

    @property
    def display_name(self) -> str:
        """User-friendly display name."""
        return self.name.lower()


class ModuleStatus(Enum):
    """Possible module states."""

    NOT_INSTALLED = auto()
    INSTALLED = auto()
    FAILED = auto()
    UNINSTALLING = auto()


@dataclass(frozen=True)
class ModuleManifest:
    """Immutable manifest data parsed from module.yaml."""

    name: str
    version: str = "1.0.0"
    description: str = ""
    platforms: frozenset[Platform] = field(default_factory=frozenset)
    depends: tuple[str, ...] = field(default_factory=tuple)
    conflicts: tuple[str, ...] = field(default_factory=tuple)
    provides: tuple[str, ...] = field(default_factory=tuple)
    requires_commands: tuple[str, ...] = field(default_factory=tuple)
    requires_env: tuple[str, ...] = field(default_factory=tuple)
    tags: frozenset[str] = field(default_factory=frozenset)
    health_check: str | None = None

    @classmethod
    def from_yaml(cls, data: dict) -> Self:
        """Parse module.yaml dict into a ModuleManifest."""
        name = data.get("name")
        if not name:
            raise ValueError("module 'name' is required")

        # Parse platforms
        platforms: list[Platform] = []
        raw_platforms = data.get("platforms", [])
        for p in raw_platforms:
            p_lower = p.lower()
            if p_lower in ("linux", "ubuntu", "debian", "fedora"):
                platforms.append(Platform.LINUX)
            elif p_lower in ("macos", "darwin", "osx"):
                platforms.append(Platform.MACOS)
            elif p_lower in ("windows", "win32"):
                platforms.append(Platform.WINDOWS)

        # Parse dependencies
        depends = tuple(data.get("depends", []))
        conflicts = tuple(data.get("conflicts", []))
        provides = tuple(data.get("provides", []))

        # Parse requirements
        requires = data.get("requires", {})
        commands = tuple(requires.get("commands", []))
        env_vars = tuple(requires.get("env", []))

        # Parse tags
        tags = frozenset(data.get("tags", []))

        return cls(
            name=name,
            version=data.get("version", "1.0.0"),
            description=data.get("description", ""),
            platforms=frozenset(platforms),
            depends=depends,
            conflicts=conflicts,
            provides=provides,
            requires_commands=commands,
            requires_env=env_vars,
            tags=tags,
            health_check=data.get("health_check"),
        )


class Module:
    """
    Represents a loaded, ready-to-use module with resolved paths.

    Scripts are stored in a dict keyed by Platform, allowing lookups
    like module.install_scripts[Platform.LINUX]
    """

    __slots__ = (
        "_manifest",
        "_path",
        "_install_scripts",
        "_uninstall_scripts",
        "_config_dir",
        "_symlonk_config",
    )

    def __init__(
        self,
        manifest: ModuleManifest,
        path: Path,
        install_scripts: dict[Platform, Path],
        uninstall_scripts: dict[Platform, Path],
        config_dir: Path | None = None,
        symlonk_config: Path | None = None,
    ) -> None:
        self._manifest = manifest
        self._path = path
        self._install_scripts = install_scripts
        self._uninstall_scripts = uninstall_scripts
        self._config_dir = config_dir
        self._symlonk_config = symlonk_config

    # Properties delegating to manifest
    @property
    def name(self) -> str:
        return self._manifest.name

    @property
    def version(self) -> str:
        return self._manifest.version

    @property
    def description(self) -> str:
        return self._manifest.description

    @property
    def depends(self) -> tuple[str, ...]:
        return self._manifest.depends

    @property
    def conflicts(self) -> tuple[str, ...]:
        return self._manifest.conflicts

    @property
    def provides(self) -> tuple[str, ...]:
        return self._manifest.provides

    @property
    def requires_commands(self) -> tuple[str, ...]:
        return self._manifest.requires_commands

    @property
    def requires_env(self) -> tuple[str, ...]:
        return self._manifest.requires_env

    @property
    def tags(self) -> frozenset[str]:
        return self._manifest.tags

    @property
    def health_check(self) -> str | None:
        return self._manifest.health_check

    @property
    def platforms(self) -> frozenset[Platform]:
        return self._manifest.platforms

    @property
    def path(self) -> Path:
        return self._path

    @property
    def config_dir(self) -> Path | None:
        return self._config_dir

    @property
    def symlonk_config(self) -> Path | None:
        """Path to symlonk.toml config file if it exists."""
        return self._symlonk_config

    @property
    def has_symlonk_config(self) -> bool:
        """Check if module has a symlonk configuration."""
        return self._symlonk_config is not None and self._symlonk_config.exists()

    @property
    def is_config_only(self) -> bool:
        """Check if module is config-only (no install scripts, just config/symlinks)."""
        # Config-only if no install scripts at all AND has symlonk or config
        return len(self._install_scripts) == 0 and (
            self.has_symlonk_config or (self._config_dir is not None and self._config_dir.exists())
        )

    @property
    def install_scripts(self) -> dict[Platform, Path]:
        """All available install scripts by platform."""
        return self._install_scripts

    @property
    def uninstall_scripts(self) -> dict[Platform, Path]:
        """All available uninstall scripts by platform."""
        return self._uninstall_scripts

    def is_available_on_platform(self, platform: Platform) -> bool:
        """Check if module is available on given platform."""
        # Config-only modules are available on all platforms
        if self.is_config_only:
            return True
        # Must have a script for this platform
        if platform not in self._install_scripts:
            return False
        # Also check manifest platforms (optional constraint)
        if self.platforms and platform not in self.platforms:
            return False
        return True

    def get_install_script(self, platform: Platform) -> Path | None:
        """Get the install script for the platform."""
        return self._install_scripts.get(platform)

    def has_install_script(self, platform: Platform) -> bool:
        """Check if module has an install script for given platform."""
        return platform in self._install_scripts

    def get_uninstall_script(self, platform: Platform) -> Path | None:
        """Get the uninstall script for the platform."""
        return self._uninstall_scripts.get(platform)

    def has_uninstall_script(self, platform: Platform) -> bool:
        """Check if module has an uninstall script for given platform."""
        return platform in self._uninstall_scripts

    def available_platforms(self) -> set[Platform]:
        """Get set of platforms where this module can be installed."""
        return set(self._install_scripts.keys())

    def __repr__(self) -> str:
        available = ", ".join(p.name.lower() for p in self._install_scripts)
        return f"Module({self.name!r}, version={self.version!r}, platforms={available})"


def _resolve_scripts(path: Path) -> tuple[dict[Platform, Path], dict[Platform, Path]]:
    """
    Resolve all platform-specific scripts in a module directory.

    Expected structure:
        install/
            linux.sh
            macos.sh
        uninstall/
            linux.sh
            macos.sh

    Returns:
        Tuple of (install_scripts, uninstall_scripts) dicts
    """
    install_scripts: dict[Platform, Path] = {}
    uninstall_scripts: dict[Platform, Path] = {}

    # Discover install scripts
    install_dir = path / "install"
    if install_dir.exists() and install_dir.is_dir():
        for script in install_dir.iterdir():
            if script.is_file() and script.suffix == ".sh":
                # Filename to platform: linux.sh -> LINUX, macos.sh -> MACOS
                name = script.stem  # "linux" from "linux.sh"
                try:
                    platform = Platform[name.upper()]
                    install_scripts[platform] = script
                    logger.debug(f"Found install script: {script}")
                except KeyError:
                    logger.warning(f"Unknown platform in filename: {script.name}")

    # Discover uninstall scripts
    uninstall_dir = path / "uninstall"
    if uninstall_dir.exists() and uninstall_dir.is_dir():
        for script in uninstall_dir.iterdir():
            if script.is_file() and script.suffix == ".sh":
                name = script.stem
                try:
                    platform = Platform[name.upper()]
                    uninstall_scripts[platform] = script
                    logger.debug(f"Found uninstall script: {script}")
                except KeyError:
                    logger.warning(f"Unknown platform in filename: {script.name}")

    return install_scripts, uninstall_scripts


def load_module(path: Path) -> Module:
    """
    Load a module from its directory.

    Args:
        path: Path to module directory containing module.yaml

    Returns:
        Module instance

    Raises:
        FileNotFoundError: If module.yaml not found
        ValueError: If YAML is invalid or required fields missing
    """
    yaml_path = path / "module.yaml"
    if not yaml_path.exists():
        raise FileNotFoundError(f"module.yaml not found in {path}")

    with open(yaml_path) as f:
        data = yaml.safe_load(f)

    if not isinstance(data, dict):
        raise ValueError(f"module.yaml must be a dictionary, got {type(data).__name__}")

    manifest = ModuleManifest.from_yaml(data)

    # Resolve script paths using new pattern
    install_scripts, uninstall_scripts = _resolve_scripts(path)

    config_dir = path / "config"
    symlonk_config = path / "symlonk.toml"

    return Module(
        manifest=manifest,
        path=path,
        install_scripts=install_scripts,
        uninstall_scripts=uninstall_scripts,
        config_dir=config_dir if config_dir.exists() else None,
        symlonk_config=symlonk_config if symlonk_config.exists() else None,
    )


def discover_modules(root: Path) -> dict[str, Module]:
    """
    Discover all modules in a directory tree.

    If root itself contains module.yaml, returns just that module.
    Otherwise, scans subdirectories for module.yaml files.

    Args:
        root: Path to scan for modules (can be a single module or directory)

    Returns:
        Dictionary mapping module names to Module instances

    Raises:
        FileNotFoundError: If root doesn't exist
    """
    if not root.exists():
        raise FileNotFoundError(f"Modules directory not found: {root}")

    # Check if root itself is a module
    if (root / "module.yaml").exists():
        try:
            module = load_module(root)
            return {module.name: module}
        except Exception as e:
            logger.warning(f"Failed to load module from {root}: {e}")
            return {}

    # Otherwise scan subdirectories
    modules: dict[str, Module] = {}
    for entry in root.iterdir():
        if entry.is_dir() and not entry.name.startswith("."):
            try:
                module = load_module(entry)
                modules[module.name] = module
                logger.debug(f"Discovered module: {module.name}")
            except FileNotFoundError:
                # No module.yaml in this directory, skip
                pass
            except Exception as e:
                logger.warning(f"Failed to load module from {entry}: {e}")

    return modules


def get_current_platform() -> Platform:
    """Get the current platform."""
    import platform

    system = platform.system().lower()
    if system in ("darwin",):
        return Platform.MACOS
    elif system in ("linux",):
        return Platform.LINUX
    elif system in ("windows",):
        return Platform.WINDOWS
    return Platform.LINUX  # Default fallback


def validate_module(module: Module) -> list[str]:
    """
    Validate a module and return list of errors.

    Args:
        module: Module to validate

    Returns:
        List of error messages (empty if valid)
    """
    errors: list[str] = []

    # Check name format
    name = module.name
    if not all(c.isalnum() or c in "-_" for c in name):
        errors.append(f"Module name '{name}' contains invalid characters")

    # Check version format (basic)
    version = module.version
    if not all(c.isalnum() or c in ".-" for c in version):
        errors.append(f"Version '{version}' contains invalid characters")

    # Check install script exists for current platform
    # BUT allow config-only modules (those with symlonk configs or config dirs)
    current = get_current_platform()
    has_install = module.has_install_script(current)
    is_config_only = module.has_symlonk_config or (module.config_dir and module.config_dir.exists())

    if not has_install and not is_config_only:
        available = ", ".join(p.name.lower() for p in module.available_platforms())
        errors.append(
            f"No install script for current platform ({current.display_name}). "
            f"Available: {available or 'none'}"
        )

    return errors
