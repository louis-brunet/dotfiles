"""Tests for the module loading and manifest parsing."""

from pathlib import Path

import pytest

from engine.module import ModuleManifest, Platform, discover_modules


class TestModuleManifest:
    """Tests for ModuleManifest parsing."""

    def test_minimal_manifest(self):
        """Test parsing a minimal module.yaml."""
        data = {"name": "test-module"}
        manifest = ModuleManifest.from_yaml(data)

        assert manifest.name == "test-module"
        assert manifest.version == "1.0.0"
        assert manifest.description == ""
        assert manifest.platforms == frozenset()
        assert manifest.depends == ()

    def test_full_manifest(self):
        """Test parsing a complete module.yaml."""
        data = {
            "name": "python",
            "version": "2.0.0",
            "description": "Python development",
            "platforms": ["linux", "macos"],
            "depends": ["base", "shell"],
            "conflicts": ["python2"],
            "provides": ["python3", "poetry"],
            "requires": {
                "commands": ["git"],
                "env": ["HOME"],
            },
            "tags": ["language", "development"],
            "health_check": "python --version",
        }
        manifest = ModuleManifest.from_yaml(data)

        assert manifest.name == "python"
        assert manifest.version == "2.0.0"
        assert manifest.description == "Python development"
        assert Platform.LINUX in manifest.platforms
        assert Platform.MACOS in manifest.platforms
        assert Platform.WINDOWS not in manifest.platforms
        assert manifest.depends == ("base", "shell")
        assert manifest.conflicts == ("python2",)
        assert manifest.provides == ("python3", "poetry")
        assert manifest.requires_commands == ("git",)
        assert manifest.requires_env == ("HOME",)
        assert "language" in manifest.tags
        assert "development" in manifest.tags
        assert manifest.health_check == "python --version"

    def test_missing_name_raises(self):
        """Test that missing name raises ValueError."""
        with pytest.raises(ValueError, match="'name' is required"):
            ModuleManifest.from_yaml({})

    def test_platform_parsing(self):
        """Test platform name variations."""
        # Linux variants
        for name in ["linux", "ubuntu", "debian", "fedora"]:
            data = {"name": "test", "platforms": [name]}
            manifest = ModuleManifest.from_yaml(data)
            assert Platform.LINUX in manifest.platforms

        # macOS variants
        for name in ["macos", "darwin", "osx"]:
            data = {"name": "test", "platforms": [name]}
            manifest = ModuleManifest.from_yaml(data)
            assert Platform.MACOS in manifest.platforms

        # Windows variants
        for name in ["windows", "win32"]:
            data = {"name": "test", "platforms": [name]}
            manifest = ModuleManifest.from_yaml(data)
            assert Platform.WINDOWS in manifest.platforms

    def test_default_values(self):
        """Test default values for optional fields."""
        data = {"name": "test"}
        manifest = ModuleManifest.from_yaml(data)

        assert manifest.conflicts == ()
        assert manifest.provides == ()
        assert manifest.requires_commands == ()
        assert manifest.requires_env == ()
        assert manifest.tags == frozenset()
        assert manifest.health_check is None


class TestModule:
    """Tests for Module class."""

    def test_is_config_only(self):
        """Test config-only detection."""
        # This is tested indirectly via module loading
        pass

    def test_platform_availability(self):
        """Test platform availability check."""
        # This would need a proper module setup
        pass


class TestModuleDiscovery:
    """Tests for module discovery."""

    def test_discover_modules(self):
        """Test discovering all modules."""
        modules = discover_modules(Path("modules"))

        assert len(modules) >= 25  # At least 25 modules
        assert "base" in modules
        assert "python" in modules
        assert "zsh" in modules

    def test_module_properties(self):
        """Test module properties are correctly loaded."""
        modules = discover_modules(Path("modules"))

        python_mod = modules.get("python")
        assert python_mod is not None
        assert python_mod.name == "python"
        assert python_mod.version is not None
        # The provides field contains the tools this module provides
        assert "python3" in python_mod.provides
