"""Tests for state management."""

from engine.state import HealthStatus, ModuleState, ModuleStateRecord, StateManager


class TestStateManager:
    """Tests for StateManager."""

    def test_new_state(self, tmp_path):
        """Test creating a new state manager."""
        state_dir = tmp_path / "state"
        manager = StateManager(state_dir)

        assert manager.get_installed() == []

    def test_set_installed(self, tmp_path):
        """Test marking a module as installed."""
        state_dir = tmp_path / "state"
        manager = StateManager(state_dir)

        manager.set_installed("python", "1.0.0", ["base"])

        assert manager.is_installed("python") is True
        assert "python" in manager.get_installed()

    def test_set_failed(self, tmp_path):
        """Test marking a module as failed."""
        state_dir = tmp_path / "state"
        manager = StateManager(state_dir)

        manager.set_failed("python", "1.0.0")

        record = manager.get("python")
        assert record is not None
        assert record.status == ModuleState.FAILED
        assert record.health == HealthStatus.ERROR

    def test_remove_module(self, tmp_path):
        """Test removing a module from state."""
        state_dir = tmp_path / "state"
        manager = StateManager(state_dir)

        manager.set_installed("python", "1.0.0", ["base"])
        assert manager.is_installed("python") is True

        manager.remove("python")
        assert manager.is_installed("python") is False

    def test_update_health(self, tmp_path):
        """Test updating health status."""
        state_dir = tmp_path / "state"
        manager = StateManager(state_dir)

        manager.set_installed("python", "1.0.0", ["base"])
        manager.update_health("python", HealthStatus.OK)

        record = manager.get("python")
        assert record is not None
        assert record.health == HealthStatus.OK

    def test_persistence(self, tmp_path):
        """Test that state persists across manager instances."""
        state_dir = tmp_path / "state"

        # Create and save state
        manager1 = StateManager(state_dir)
        manager1.set_installed("python", "1.0.0", ["base"])

        # Create new manager with same directory
        manager2 = StateManager(state_dir)

        assert manager2.is_installed("python") is True

    def test_get_not_installed(self, tmp_path):
        """Test getting state for non-installed module."""
        state_dir = tmp_path / "state"
        manager = StateManager(state_dir)

        # Module was never installed
        assert manager.is_installed("python") is False

        # Get returns None
        assert manager.get("python") is None


class TestModuleStateRecord:
    """Tests for ModuleStateRecord."""

    def test_from_dict(self):
        """Test creating record from dict."""
        data = {
            "status": "installed",
            "version": "1.0.0",
            "installed_at": 1234567890.0,
            "last_checked": 1234567890.0,
            "health": "ok",
            "depends_on": ["base"],
        }
        record = ModuleStateRecord.from_dict(data)

        assert record.status == ModuleState.INSTALLED
        assert record.version == "1.0.0"
        assert record.health == HealthStatus.OK
        assert record.depends_on == ("base",)

    def test_to_dict(self):
        """Test converting record to dict."""
        record = ModuleStateRecord(
            status=ModuleState.INSTALLED,
            version="1.0.0",
            installed_at=1234567890.0,
            last_checked=1234567890.0,
            health=HealthStatus.OK,
            depends_on=("base",),
        )

        data = record.to_dict()

        assert data["status"] == "installed"
        assert data["version"] == "1.0.0"
        assert data["health"] == "ok"
