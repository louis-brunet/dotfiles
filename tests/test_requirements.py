"""Tests for requirements checking."""

import os
from pathlib import Path
from unittest.mock import patch

from engine.module import Module, ModuleManifest
from engine.requirements import RequirementChecker


def make_module(name: str, requires_commands=(), requires_env=(), provides=()) -> Module:
    """Helper to create a test module with requirements."""
    manifest = ModuleManifest(
        name=name,
        requires_commands=requires_commands,
        requires_env=requires_env,
        provides=provides,
    )
    return Module(
        manifest=manifest,
        path=Path(f"modules/{name}"),
        install_scripts={},
        uninstall_scripts={},
    )


class TestRequirementChecker:
    """Tests for RequirementChecker."""

    def test_check_command_exists(self):
        """Test checking a command that exists."""
        checker = RequirementChecker()
        check = checker.check_command("ls")

        assert check.type == "command"
        assert check.name == "ls"
        assert check.satisfied is True
        assert "found" in check.message.lower()

    def test_check_command_not_exists(self):
        """Test checking a command that doesn't exist."""
        checker = RequirementChecker()
        check = checker.check_command("nonexistent_command_xyz")

        assert check.type == "command"
        assert check.satisfied is False
        assert "NOT FOUND" in check.message

    def test_check_env_var_set(self):
        """Test checking an environment variable that is set."""
        checker = RequirementChecker()

        with patch.dict(os.environ, {"TEST_VAR": "value"}):
            check = checker.check_env("TEST_VAR")

        assert check.type == "env"
        assert check.name == "TEST_VAR"
        assert check.satisfied is True

    def test_check_env_var_not_set(self):
        """Test checking an environment variable that is not set."""
        checker = RequirementChecker()
        check = checker.check_env("NONEXISTENT_VAR_XYZ")

        assert check.type == "env"
        assert check.satisfied is False
        assert "NOT SET" in check.message

    def test_check_env_var_empty(self):
        """Test checking an environment variable that is empty."""
        checker = RequirementChecker()

        with patch.dict(os.environ, {"EMPTY_VAR": ""}):
            check = checker.check_env("EMPTY_VAR")

        assert check.satisfied is False
        assert "EMPTY" in check.message

    def test_check_module_with_commands(self):
        """Test checking a module's command requirements."""
        checker = RequirementChecker()
        module = make_module("test", requires_commands=["ls", "nonexistent"])

        checks = checker.check_module(module)

        assert len(checks) == 2
        # Order may vary, check contents
        command_checks = [c for c in checks if c.type == "command"]
        assert len(command_checks) == 2

    def test_check_module_with_env(self):
        """Test checking a module's environment variable requirements."""
        checker = RequirementChecker()

        with patch.dict(os.environ, {"HOME": "/home/user"}):
            module = make_module("test", requires_env=["HOME", "NONEXISTENT"])
            checks = checker.check_module(module)

        env_checks = [c for c in checks if c.type == "env"]
        assert len(env_checks) == 2

        home_check = next(c for c in env_checks if c.name == "HOME")
        assert home_check.satisfied is True

        nonexistent = next(c for c in env_checks if c.name == "NONEXISTENT")
        assert nonexistent.satisfied is False

    def test_get_unsatisfied_empty(self):
        """Test get_unsatisfied returns empty when all satisfied."""
        checker = RequirementChecker()
        module = make_module("test", requires_commands=["ls"])

        unsatisfied = checker.get_unsatisfied(module)

        assert unsatisfied == []

    def test_get_unsatisfied_returns_failed(self):
        """Test get_unsatisfied returns failed requirements."""
        checker = RequirementChecker()
        module = make_module("test", requires_commands=["ls", "nonexistent_cmd"])

        unsatisfied = checker.get_unsatisfied(module)

        assert len(unsatisfied) == 1
        assert unsatisfied[0].name == "nonexistent_cmd"

    def test_is_satisfied_true(self):
        """Test is_satisfied returns True when all requirements met."""
        checker = RequirementChecker()
        module = make_module("test", requires_commands=["ls"])

        assert checker.is_satisfied(module) is True

    def test_is_satisfied_false(self):
        """Test is_satisfied returns False when requirements not met."""
        checker = RequirementChecker()
        module = make_module("test", requires_commands=["nonexistent_cmd"])

        assert checker.is_satisfied(module) is False

    def test_module_provides_requirement(self):
        """Test that modules can provide commands via provides field."""
        # This tests the logic used in cli.py
        # A module that requires 'python' should be satisfied if another module provides it

        requires_module = make_module("app", requires_commands=["python3"], provides=())
        provides_module = make_module("python", requires_commands=(), provides=("python3",))

        # Check logic: does provides_module provide python3?
        assert "python3" in provides_module.provides
        # Check logic: does requires_module need python3?
        assert "python3" in requires_module.requires_commands
