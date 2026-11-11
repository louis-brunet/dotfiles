"""Tests for the dependency graph."""

from pathlib import Path

import pytest

from engine.graph import DependencyGraph
from engine.module import Module, ModuleManifest


def make_module(name: str, depends: tuple = ()) -> Module:
    """Helper to create a test module."""
    manifest = ModuleManifest(
        name=name,
        depends=depends,
    )
    return Module(
        manifest=manifest,
        path=Path(f"modules/{name}"),
        install_scripts={},
        uninstall_scripts={},
    )


class TestDependencyGraph:
    """Tests for DependencyGraph."""

    def test_simple_chain(self):
        """Test a simple dependency chain: a → b → c."""
        modules = {
            "a": make_module("a", ()),
            "b": make_module("b", ("a",)),
            "c": make_module("c", ("b",)),
        }

        graph = DependencyGraph(modules=modules)
        order = graph.resolve_install_order(["c"])

        assert order == ["a", "b", "c"]

    def test_multiple_dependencies(self):
        """Test module with multiple dependencies."""
        modules = {
            "base": make_module("base", ()),
            "shell": make_module("shell", ("base",)),
            "zsh": make_module("zsh", ("shell",)),
            "git": make_module("git", ("base",)),
        }

        graph = DependencyGraph(modules=modules)
        order = graph.resolve_install_order(["zsh", "git"])

        # base must come first
        assert order.index("base") < order.index("shell")
        assert order.index("base") < order.index("zsh")
        assert order.index("base") < order.index("git")
        # shell must come before zsh
        assert order.index("shell") < order.index("zsh")

    def test_independent_modules(self):
        """Test independent modules can be installed in any order."""
        modules = {
            "a": make_module("a", ()),
            "b": make_module("b", ()),
            "c": make_module("c", ()),
        }

        graph = DependencyGraph(modules=modules)
        order = graph.resolve_install_order(["a", "b", "c"])

        assert set(order) == {"a", "b", "c"}

    def test_circular_dependency_raises(self):
        """Test that circular dependencies raise ValueError."""
        modules = {
            "a": make_module("a", ("b",)),
            "b": make_module("b", ("a",)),
        }

        graph = DependencyGraph(modules=modules)

        with pytest.raises(ValueError, match="Circular dependency"):
            graph.resolve_install_order(["a", "b"])

    def test_unknown_dependency_warning(self):
        """Test that unknown dependencies generate a warning (not an error)."""
        modules = {
            "a": make_module("a", ("unknown",)),
        }

        graph = DependencyGraph(modules=modules)

        # The graph logs a warning but doesn't raise - it just skips the unknown dependency
        # This is the expected behavior - we can still get install order but it won't include the unknown
        order = graph.resolve_install_order(["a"])
        # The unknown dep won't be in the order since it doesn't exist
        assert "unknown" not in order

    def test_transitive_dependencies(self):
        """Test getting all transitive dependencies."""
        modules = {
            "base": make_module("base", ()),
            "shell": make_module("shell", ("base",)),
            "zsh": make_module("zsh", ("shell",)),
            "git": make_module("git", ("base",)),
        }

        graph = DependencyGraph(modules=modules)

        deps = graph.get_transitive_dependencies("zsh")
        assert deps == {"base", "shell"}

    def test_transitive_dependents(self):
        """Test getting all transitive dependents."""
        modules = {
            "base": make_module("base", ()),
            "shell": make_module("shell", ("base",)),
            "zsh": make_module("zsh", ("shell",)),
        }

        graph = DependencyGraph(modules=modules)

        dependents = graph.get_transitive_dependents("base")
        assert dependents == {"shell", "zsh"}

    def test_cycle_detection(self):
        """Test cycle detection."""
        modules = {
            "a": make_module("a", ("b",)),
            "b": make_module("b", ("c",)),
            "c": make_module("c", ("a",)),
        }

        graph = DependencyGraph(modules=modules)
        cycles = graph.detect_cycles()

        assert len(cycles) > 0

    def test_no_cycles(self):
        """Test that acyclic graphs return empty cycles."""
        modules = {
            "a": make_module("a", ()),
            "b": make_module("b", ("a",)),
            "c": make_module("c", ("b",)),
        }

        graph = DependencyGraph(modules=modules)
        cycles = graph.detect_cycles()

        assert cycles == []

    def test_topological_sort(self):
        """Test topological sort returns valid order."""
        modules = {
            "base": make_module("base", ()),
            "shell": make_module("shell", ("base",)),
            "zsh": make_module("zsh", ("shell",)),
            "git": make_module("git", ("base",)),
        }

        graph = DependencyGraph(modules=modules)
        order = graph.topological_sort()

        # Verify all modules present
        assert set(order) == {"base", "shell", "zsh", "git"}
        # Verify dependencies come before dependents
        assert order.index("base") < order.index("shell")
        assert order.index("base") < order.index("git")
        assert order.index("shell") < order.index("zsh")
