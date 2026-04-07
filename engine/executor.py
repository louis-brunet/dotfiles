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

    def _stream_process(self, process: subprocess.Popen) -> tuple[str, str]:
        """
        Stream stdout and stderr from a running process to the console in real time.

        Lines are printed as they arrive; both streams are also accumulated and
        returned for inclusion in the ExecutionResult.

        Args:
            process: A running Popen instance opened with stdout=PIPE, stderr=PIPE.

        Returns:
            (stdout, stderr) as joined strings.
        """
        import select

        console = get_console()
        stdout_lines: list[str] = []
        stderr_lines: list[str] = []

        # Use select-based multiplexing when on a Unix-like system so we can
        # interleave stdout and stderr without blocking on either.
        if hasattr(select, "select") and process.stdout and process.stderr:
            readable = {
                process.stdout.fileno(): (process.stdout, stdout_lines, "stdout"),
                process.stderr.fileno(): (process.stderr, stderr_lines, "stderr"),
            }
            open_fds = set(readable.keys())

            while open_fds:
                try:
                    ready, _, _ = select.select(list(open_fds), [], [], 0.1)
                except ValueError:
                    # One of the fds was already closed.
                    break

                for fd in ready:
                    stream, accumulator, stream_name = readable[fd]
                    line = stream.readline()
                    if line:
                        text = line.rstrip("\n")
                        accumulator.append(text)
                        # Route stderr lines as warnings, stdout as plain output.
                        if stream_name == "stderr":
                            console.debug(f"  stderr | {text}")
                        else:
                            console.debug(f"         {text}")
                    else:
                        # EOF on this stream.
                        open_fds.discard(fd)

        else:
            # Fallback: read stdout line-by-line (stderr captured separately).
            if process.stdout:
                for line in process.stdout:
                    text = line.rstrip("\n")
                    stdout_lines.append(text)
                    console.debug(f"         {text}")
            if process.stderr:
                stderr_data = process.stderr.read()
                if stderr_data:
                    for line in stderr_data.splitlines():
                        stderr_lines.append(line)
                        console.debug(f"  stderr | {line}")

        return "\n".join(stdout_lines), "\n".join(stderr_lines)

    def execute(self, module: Module, action: str = "install") -> ExecutionResult:
        """
        Execute a module's script.

        Args:
            module: Module to execute
            action: "install" or "uninstall"

        Returns:
            ExecutionResult with success/failure info
        """
        console = get_console()
        start = time.perf_counter()

        console.info(f"[{module.name}] Starting {action}...")

        # Determine script path
        script: Path | None = None
        current_platform = get_current_platform()

        console.debug(f"[{module.name}] Resolving {action} script for platform: {current_platform.name}")

        if action == "install":
            script = module.get_install_script(current_platform)
        elif action == "uninstall":
            script = module.get_uninstall_script(current_platform)

        if script is None:
            console.info(
                f"[{module.name}] No {action} script for {current_platform.name} — skipping"
            )
            return ExecutionResult(
                success=True,
                message=f"No {action} script for {module.name} on {current_platform.name} - skipped",
                duration=time.perf_counter() - start,
            )

        console.debug(f"[{module.name}] Script resolved: {script}")

        if not script.exists():
            console.error(f"[{module.name}] Script not found: {script}")
            return ExecutionResult(
                success=False,
                message=f"Script not found: {script}",
                duration=time.perf_counter() - start,
            )

        # Make executable if needed
        if not script.stat().st_mode & 0o111:
            console.debug(f"[{module.name}] Script is not executable — chmod +x")
            script.chmod(script.stat().st_mode | 0o111)

        # Prepare environment
        env = {
            **os.environ,
            "DOTFILES_MODULE": module.name,
            "DOTFILES_MODULE_PATH": str(module.path.absolute()),
        }

        script_path = str(script.absolute())

        console.info(f"[{module.name}] Running: {script_path}")
        console.debug(f"[{module.name}] Working directory: {module.path.absolute()}")

        try:
            process = subprocess.Popen(
                [script_path],
                cwd=str(module.path.absolute()),
                env=env,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
            )

            # Stream output to console in real time and accumulate for the result.
            stdout, stderr = self._stream_process(process)

            # Wait for the process to finish (it should already be done after
            # _stream_process drains the pipes, but we still need the returncode).
            try:
                process.wait(timeout=300)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait()
                duration = time.perf_counter() - start
                console.error(f"[{module.name}] {action} timed out after 5 minutes")
                return ExecutionResult(
                    success=False,
                    message=f"{module.name} {action} timed out after 5 minutes",
                    duration=duration,
                    stdout=stdout,
                    stderr=stderr,
                )

            duration = time.perf_counter() - start
            success = process.returncode == 0

            if success:
                console.info(
                    f"[{module.name}] {action.capitalize()} succeeded "
                    f"(exit 0, {duration:.2f}s)"
                )
                return ExecutionResult(
                    success=True,
                    message=f"{module.name} {action}ed successfully",
                    duration=duration,
                    stdout=stdout,
                    stderr=stderr,
                )
            else:
                console.error(
                    f"[{module.name}] {action.capitalize()} failed "
                    f"(exit {process.returncode}, {duration:.2f}s)"
                )
                if stderr:
                    console.error(f"[{module.name}] Last stderr:\n{stderr[-500:]}")
                return ExecutionResult(
                    success=False,
                    message=f"{module.name} {action} failed (exit {process.returncode})",
                    duration=duration,
                    stdout=stdout,
                    stderr=stderr,
                )

        except Exception as e:
            duration = time.perf_counter() - start
            console.error(f"[{module.name}] Unexpected error during {action}: {e}")
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
        console = get_console()
        results: dict[str, ExecutionResult] = {}
        total = len(order)

        console.info(f"Beginning installation: {total} module(s) in queue")
        console.debug(f"Execution order: {', '.join(order)}")

        for index, name in enumerate(order, start=1):
            module = modules[name]

            console.info(f"[{index}/{total}] Processing module: {name}")

            # Skip if already installed
            if self._state.is_installed(name):
                console.info(f"[{name}] Already installed — skipping")
                results[name] = ExecutionResult(
                    success=True,
                    message=f"{name} already installed",
                    duration=0.0,
                )
                continue

            if module.depends:
                console.debug(f"[{name}] Dependencies: {', '.join(module.depends)}")

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
                console.info(f"[{name}] State updated: installed (version {module.version})")
            else:
                self._state.set_failed(name, module.version)
                console.error(
                    f"[{name}] State updated: failed — "
                    f"stopping execution ({index}/{total} completed)"
                )
                break

        succeeded = sum(1 for r in results.values() if r.success)
        failed = sum(1 for r in results.values() if r.failed)
        console.info(
            f"Installation complete: {succeeded} succeeded, {failed} failed "
            f"out of {len(results)} processed"
        )

        return results
