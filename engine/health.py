"""
Health checking for the dotfiles engine.
"""

import subprocess
from dataclasses import dataclass

from .module import Module, Platform
from .state import HealthStatus, StateManager


@dataclass(frozen=True)
class HealthResult:
    """Result of a health check."""

    module_name: str
    status: HealthStatus
    message: str
    output: str = ""


class HealthChecker:
    """Executes health checks for modules."""

    def __init__(self, state_manager: StateManager) -> None:
        self._state = state_manager

    def check(self, module: Module, platform: Platform) -> HealthResult:
        """
        Run health check for a module.

        Args:
            module: Module to check
            platform: Current platform

        Returns:
            HealthResult with status and message
        """
        # Check if module is installed
        record = self._state.get(module.name)
        if not record or record.status.value != "installed":
            return HealthResult(
                module_name=module.name,
                status=HealthStatus.UNKNOWN,
                message="not installed",
            )

        # Check if health check is defined
        if not module.health_check:
            return HealthResult(
                module_name=module.name,
                status=HealthStatus.UNKNOWN,
                message="no health check defined",
            )

        # Get install script to determine working directory
        script = module.get_install_script(platform)
        if not script:
            return HealthResult(
                module_name=module.name,
                status=HealthStatus.ERROR,
                message="no install script found",
            )

        # Execute health check command
        try:
            result = subprocess.run(
                module.health_check,
                shell=True,
                cwd=str(module.path.absolute()),
                capture_output=True,
                text=True,
                timeout=30,
            )

            if result.returncode == 0:
                return HealthResult(
                    module_name=module.name,
                    status=HealthStatus.OK,
                    message="healthy",
                    output=result.stdout.strip(),
                )
            else:
                return HealthResult(
                    module_name=module.name,
                    status=HealthStatus.ERROR,
                    message=f"health check failed (exit {result.returncode})",
                    output=result.stderr.strip() or result.stdout.strip(),
                )

        except subprocess.TimeoutExpired:
            return HealthResult(
                module_name=module.name,
                status=HealthStatus.ERROR,
                message="health check timed out",
            )
        except Exception as e:
            return HealthResult(
                module_name=module.name,
                status=HealthStatus.ERROR,
                message=f"error: {e}",
            )

    def check_all(
        self,
        modules: dict[str, Module],
        platform: Platform,
    ) -> dict[str, HealthResult]:
        """
        Run health checks for all installed modules.

        Returns:
            Dict mapping module name to HealthResult
        """
        results: dict[str, HealthResult] = {}

        for name, module in modules.items():
            result = self.check(module, platform)
            results[name] = result

            # Update state with health status
            if result.status != HealthStatus.UNKNOWN:
                self._state.update_health(name, result.status)

        return results
