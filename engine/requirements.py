"""Requirement validation for module prerequisites."""

import os
import shutil
from dataclasses import dataclass


@dataclass(frozen=True)
class RequirementCheck:
    """Result of checking a requirement."""

    name: str
    type: str  # "command" or "env"
    satisfied: bool
    message: str


class RequirementChecker:
    """Checks if module requirements are met."""

    def check_command(self, command: str) -> RequirementCheck:
        """Check if a command exists."""
        exists = shutil.which(command) is not None
        return RequirementCheck(
            name=command,
            type="command",
            satisfied=exists,
            message=f"Command '{command}' {'found' if exists else 'NOT FOUND'}",
        )

    def check_env(self, env_var: str) -> RequirementCheck:
        """Check if an environment variable is set and not empty."""
        exists = env_var in os.environ and os.environ[env_var] != ""
        return RequirementCheck(
            name=env_var,
            type="env",
            satisfied=exists,
            message=f"Environment variable '{env_var}' {'set' if exists else 'NOT SET or EMPTY'}",
        )

    def check_module(self, module: "Module") -> list[RequirementCheck]:
        """Check all requirements for a module."""

        checks = []

        # Check commands
        for cmd in module.requires_commands:
            checks.append(self.check_command(cmd))

        # Check environment variables
        for env in module.requires_env:
            checks.append(self.check_env(env))

        return checks

    def get_unsatisfied(self, module: "Module") -> list[RequirementCheck]:
        """Get only unsatisfied requirements for a module."""

        return [c for c in self.check_module(module) if not c.satisfied]

    def is_satisfied(self, module: "Module") -> bool:
        """Check if all requirements are satisfied."""
        return len(self.get_unsatisfied(module)) == 0
