"""Tests for symlink management."""

from engine.symlinks import SymlinkDiff, SymlinkEntry


class TestSymlinkEntry:
    """Tests for SymlinkEntry."""

    def test_creation(self):
        """Test creating a SymlinkEntry."""
        entry = SymlinkEntry(target="~/.zshrc", source="/dotfiles/zsh/zshrc")
        assert entry.target == "~/.zshrc"
        assert entry.source == "/dotfiles/zsh/zshrc"


class TestSymlinkDiff:
    """Tests for SymlinkDiff."""

    def test_creation(self):
        """Test creating a SymlinkDiff."""
        diff = SymlinkDiff(
            target="~/.zshrc",
            old_source="/dotfiles/zsh/zshrc",
            new_source="/dotfiles/modules/zsh/zshrc",
            action="update",
        )
        assert diff.target == "~/.zshrc"
        assert diff.action == "update"

    def test_actions(self):
        """Test different diff actions."""
        diff_keep = SymlinkDiff("~/.zshrc", "/old", "/old", "keep")
        diff_update = SymlinkDiff("~/.zshrc", "/old", "/new", "update")
        diff_add = SymlinkDiff("~/.zshrc", None, "/new", "add")
        diff_remove = SymlinkDiff("~/.zshrc", "/old", None, "remove")

        assert diff_keep.action == "keep"
        assert diff_update.action == "update"
        assert diff_add.action == "add"
        assert diff_remove.action == "remove"
