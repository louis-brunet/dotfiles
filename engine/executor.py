"""
Module execution for the dotfiles engine.

This module provides:
- Executor: runs install/uninstall scripts
- ExecutionResult: captures execution outcome
"""

import os
import subprocess
import time
from dataclasses import dataclass
from pathlib import Path

from .console import get_console
from .module import Module, get_current_platform
from .state import StateManager


@dataclass(frozen=True)
class ExecutionResult:
    """Result of a module operation."""

    success: bool
    message: str
    duration: float
    stdout: str = ""
    stderr: str = ""

    @property
    def failed(self) -> bool:
        return not self.success


class Executor:
    """Executes module install/uninstall scripts."""

    def __init__(self, state_manager: StateManager) -> None:
        self._state = state_manager

    def execute(self, module: Module, action: str = "install") -> ExecutionResult:
        """
        Execute a module's script.

        Args:
            module: Module to execute
            action: "install" or "uninstall"

        Returns:
            ExecutionResult with success/failure info
        """
        start = time.perf_counter()

        # Determine script path
        script: Path | None = None
        current_platform = get_current_platform()

        if action == "install":
            script = module.get_install_script(current_platform)
        elif action == "uninstall":
            script = module.get_uninstall_script(current_platform)

        if script is None:
            console = get_console()
            console.info(
                f"Module {module.name} has no {action} script for {current_platform.name} - skipping"
            )
            return ExecutionResult(
                success=True,
                message=f"No {action} script for {module.name} on {current_platform.name} - skipped",
                duration=time.perf_counter() - start,
            )

        if not script.exists():
            return ExecutionResult(
                success=False,
                message=f"Script not found: {script}",
                duration=time.perf_counter() - start,
            )

        # Make executable if needed
        if not script.stat().st_mode & 0o111:
            script.chmod(script.stat().st_mode | 0o111)

        # Prepare environment
        env = {
            **os.environ,
            "DOTFILES_MODULE": module.name,
            "DOTFILES_MODULE_PATH": str(module.path.absolute()),
        }

        # Use absolute path for script
        script_path = str(script.absolute())

        try:
            result = subprocess.run(
                [script_path],
                cwd=str(module.path.absolute()),
                env=env,
                capture_output=True,
                text=True,
                timeout=300,  # 5 minute timeout
            )

            duration = time.perf_counter() - start
            success = result.returncode == 0

            if success:
                console = get_console()
                console.debug(f"{module.name} {action}ed successfully ({duration:.2f}s)")
                return ExecutionResult(
                    success=True,
                    message=f"{module.name} {action}ed successfully",
                    duration=duration,
                    stdout=result.stdout,
                    stderr=result.stderr,
                )
            else:
                console = get_console()
                console.error(f"{module.name} {action} failed: {result.stderr}")
                return ExecutionResult(
                    success=False,
                    message=f"{module.name} {action} failed (exit {result.returncode})",
                    duration=duration,
                    stdout=result.stdout,
                    stderr=result.stderr,
                )

        except subprocess.TimeoutExpired:
            duration = time.perf_counter() - start
            console = get_console()
            console.error(f"{module.name} {action} timed out")
            return ExecutionResult(
                success=False,
                message=f"{module.name} {action} timed out after 5 minutes",
                duration=duration,
            )
        except Exception as e:
            duration = time.perf_counter() - start
            console = get_console()
            console.error(f"{module.name} {action} error: {e}")
            return ExecutionResult(
                success=False,
                message=f"{module.name} {action} error: {e}",
                duration=duration,
            )

    def execute_order(
        self,
        order: list[str],
        modules: dict[str, Module],
    ) -> dict[str, ExecutionResult]:
        """
        Execute modules in specified order.

        Stops on first failure unless configured otherwise.

        Args:
            order: Module names in execution order
            modules: Module registry

        Returns:
            Dict mapping module name to ExecutionResult
        """
        results: dict[str, ExecutionResult] = {}

        for name in order:
            module = modules[name]

            # Skip if already installed
            if self._state.is_installed(name):
                console = get_console()
                console.debug(f"{name} already installed, skipping")
                results[name] = ExecutionResult(
                    success=True,
                    message=f"{name} already installed",
                    duration=0.0,
                )
                continue

            # Execute
            result = self.execute(module, "install")
            results[name] = result

            # Update state
            if result.success:
                self._state.set_installed(
                    module_name=name,
                    version=module.version,
                    depends_on=list(module.depends),
                )
            else:
                self._state.set_failed(name, module.version)
                console = get_console()
                console.error("Installation failed, stopping")
                break

        return results
