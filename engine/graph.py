"""
Dependency graph management for the dotfiles engine.

This module provides:
- DependencyGraph: manages module dependencies and resolution
- Cycle detection
- Topological sorting
- Installation order resolution
"""

import logging
from collections import deque
from dataclasses import dataclass, field

from .module import Module

logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class DependencyEdge:
    """Represents a directed edge in the dependency graph."""

    from_module: str
    to_module: str  # to depends on from


@dataclass
class DependencyGraph:
    """Manages module dependencies and resolution."""

    modules: dict[str, Module] = field(default_factory=dict)
    _adjacency: dict[str, set[str]] = field(default_factory=dict)
    _reverse_adj: dict[str, set[str]] = field(default_factory=dict)
    _initialized: bool = field(default=False, repr=False)

    def _ensure_initialized(self) -> None:
        """Lazy initialization of graph structure."""
        if self._initialized:
            return

        # Initialize all nodes
        for name in self.modules:
            if name not in self._adjacency:
                self._adjacency[name] = set()
                self._reverse_adj[name] = set()

        # Build edges
        for name, module in self.modules.items():
            for dep in module.depends:
                if dep in self.modules:
                    self._adjacency[dep].add(name)
                    self._reverse_adj[name].add(dep)
                else:
                    logger.warning(f"Module '{name}' depends on unknown module '{dep}'")

        self._initialized = True

    def add_module(self, module: Module) -> None:
        """Add a module to the graph."""
        self.modules[module.name] = module
        self._initialized = False  # Need to rebuild

    def get_dependencies(self, name: str) -> set[str]:
        """Get direct dependencies of a module."""
        self._ensure_initialized()
        if name not in self.modules:
            raise KeyError(f"Unknown module: {name}")
        return self._reverse_adj.get(name, set()).copy()

    def get_dependents(self, name: str) -> set[str]:
        """Get modules that depend on this module."""
        self._ensure_initialized()
        if name not in self.modules:
            raise KeyError(f"Unknown module: {name}")
        return self._adjacency.get(name, set()).copy()

    def get_transitive_dependencies(self, name: str) -> set[str]:
        """Get all transitive dependencies (recursive)."""
        self._ensure_initialized()
        if name not in self.modules:
            raise KeyError(f"Unknown module: {name}")

        visited: set[str] = set()
        queue = deque([name])

        while queue:
            current = queue.popleft()
            for dep in self._reverse_adj.get(current, set()):
                if dep not in visited:
                    visited.add(dep)
                    queue.append(dep)

        visited.discard(name)
        return visited

    def get_transitive_dependents(self, name: str) -> set[str]:
        """Get all modules that transitively depend on this module."""
        self._ensure_initialized()
        if name not in self.modules:
            raise KeyError(f"Unknown module: {name}")

        visited: set[str] = set()
        queue = deque([name])

        while queue:
            current = queue.popleft()
            for dep in self._adjacency.get(current, set()):
                if dep not in visited:
                    visited.add(dep)
                    queue.append(dep)

        visited.discard(name)
        return visited

    def get_transitive_closure(self, names: list[str]) -> set[str]:
        """Get the transitive closure of a set of modules (includes all deps)."""
        self._ensure_initialized()

        # Validate all names exist
        for name in names:
            if name not in self.modules:
                raise KeyError(f"Unknown module: {name}")

        closure = set(names)
        for name in names:
            closure.update(self.get_transitive_dependencies(name))

        return closure

    def resolve_install_order(self, targets: list[str]) -> list[str]:
        """
        Resolve installation order for target modules.

        Args:
            targets: Module names to install

        Returns:
            List of module names in dependency-respecting order

        Raises:
            KeyError: If unknown module referenced
            ValueError: If circular dependency detected
        """
        self._ensure_initialized()

        # Validate targets
        for name in targets:
            if name not in self.modules:
                raise KeyError(f"Unknown module: {name}")

        # Get transitive closure
        to_install = list(self.get_transitive_closure(targets))

        # Create subgraph with only relevant modules
        subgraph = {name: self.modules[name] for name in to_install}
        subgraph_graph = DependencyGraph(modules=subgraph)
        subgraph_graph._initialized = True

        # Build local adjacency for topo sort
        adj: dict[str, set[str]] = {name: set() for name in to_install}
        reverse_adj: dict[str, set[str]] = {name: set() for name in to_install}

        for name in to_install:
            for dep in self._reverse_adj.get(name, set()):
                if dep in to_install:
                    reverse_adj[name].add(dep)
                    adj[dep].add(name)

        # Kahn's algorithm
        in_degree = {name: len(reverse_adj[name]) for name in to_install}
        queue = deque(name for name, degree in in_degree.items() if degree == 0)
        result: list[str] = []

        while queue:
            node = queue.popleft()
            result.append(node)

            for neighbor in adj.get(node, set()):
                in_degree[neighbor] -= 1
                if in_degree[neighbor] == 0:
                    queue.append(neighbor)

        if len(result) != len(to_install):
            cycles = self._find_cycles_in_set(to_install)
            raise ValueError(f"Circular dependency detected: {cycles}")

        return result

    def detect_cycles(self) -> list[list[str]]:
        """Detect all cycles in the dependency graph."""
        self._ensure_initialized()
        return self._find_cycles_in_set(list(self.modules.keys()))

    def _find_cycles_in_set(self, nodes: list[str]) -> list[list[str]]:
        """Find cycles among a specific set of nodes using DFS."""
        visited: set[str] = set()
        rec_stack: set[str] = set()
        cycles: list[list[str]] = []

        def dfs(node: str, path: list[str]) -> None:
            if node in rec_stack:
                # Found cycle
                idx = path.index(node)
                cycles.append(path[idx:] + [node])
                return

            if node in visited:
                return

            visited.add(node)
            rec_stack.add(node)
            path.append(node)

            for dep in self._reverse_adj.get(node, set()):
                if dep in nodes:
                    dfs(dep, path)

            path.pop()
            rec_stack.remove(node)

        for node in nodes:
            if node not in visited:
                dfs(node, [])

        return cycles

    def topological_sort(self) -> list[str]:
        """
        Return modules in topological order (all dependencies first).

        Raises:
            ValueError: If circular dependency detected
        """
        self._ensure_initialized()
        return self.resolve_install_order(list(self.modules.keys()))

    def __repr__(self) -> str:
        return f"DependencyGraph({len(self.modules)} modules)"
