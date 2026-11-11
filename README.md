# Dotfiles

Personal dotfiles configuration with modular management.

## Prerequisites

- Python 3.13+
- [uv](https://github.com/astral-sh/uv) for package management
- [symlonk](https://github.com/louis-brunet/symlonk) for symlink management

## Quick Start

### New Setup

```bash
# Clone dotfiles
git clone https://github.com/yourusername/dotfiles.git
cd dotfiles

# Setup git config
uv run python -m engine.cli gitconfig --name "Your Name" --email "you@example.com"

# Install modules
uv run python -m engine.cli install

# Create symlinks
uv run python -m engine.cli symlinks --create --verify --prune
```

### Ongoing Usage

```bash
# Install all modules
uv run python -m engine.cli install

# Install specific modules
uv run python -m engine.cli install base shell zsh

# List available modules
uv run python -m engine.cli list

# Check status
uv run python -m engine.cli status

# Check status with health
uv run python -m engine.cli status --health

# Verify symlinks
uv run python -m engine.cli symlinks --verify --prune
```

## Commands

| Command | Description |
|---------|-------------|
| `list` | List all available modules |
| `status` | Show installation status |
| `status --health` | Show status with health checks |
| `install [modules]` | Install modules (default: all) |
| `install <module>` | Install specific module(s) |
| `uninstall <module>` | Uninstall a module |
| `graph [module]` | Show dependency graph |
| `gitconfig` | Setup git local config |
| `symlinks` | Manage symlinks via symlonk |
| `symlinks-migrate` | Migrate symlinks to new paths (--diff, --verify-targets) |
| `symlinks-rollback` | Rollback symlinks to backup |

### Install Options

- `--dry-run` - Preview what would be installed
- `--force` - Reinstall if already installed
- `--ignore-requirements` - Install even with missing requirements

## Module Schema

Each module lives in `modules/<name>/` and must have a `module.yaml` file:

```yaml
# Required fields
name: <module-name>           # Unique module identifier
description: "Description"     # Human-readable description

# Optional fields
version: "1.0.0"              # Version string (default: "1.0.0")

platforms:                    # Supported platforms
  - linux
  - macos
  - any                       # Special: works on all platforms

depends:                      # Module dependencies (installed first)
  - base
  - shell

conflicts:                   # Incompatible modules (cannot be installed together)
  - other-module

provides:                    # Commands/tools this module provides
  - git
  - curl

requires:                    # Requirements (checked before install)
  commands:                  # Required commands that must exist
    - git
    - curl
  env:                       # Required environment variables
    - HOME

tags:                        # Categorization tags
  - system
  - config

health_check: |              # Health check command (shell script)
  git --version
```

### Module Structure

```
modules/<name>/
├── module.yaml           # Module metadata (required)
├── install/             # Installation scripts
│   ├── linux.sh         # Linux install script
│   └── macos.sh         # macOS install script
├── uninstall/           # Uninstallation scripts
│   ├── linux.sh
│   └── macos.sh
├── config/              # Configuration files
├── symlonk.toml         # Symlink definitions
└── *.zsh                # Shell configuration files
```

### Dependency Resolution

The engine automatically resolves dependencies and installs modules in the correct order. Use `graph` command to visualize:

```bash
uv run python -m engine.cli graph
```

## Development

### Running Tests

```bash
make test
# or
uv run pytest tests/
```

### Code Quality

```bash
# Lint
make lint
# or
uv run ruff check engine/ tests/

# Format
make format
# or
uv run ruff format engine/ tests/

# Check (lint + test)
make check
```

### Pre-commit Hooks

```bash
# Install pre-commit
make pre-commit-install
# or
uv pip install pre-commit

# Run pre-commit
make pre-commit
# or
uv run pre-commit run --all-files
```

### Using the Makefile

```bash
make install     # Install all modules
make bootstrap   # Legacy bootstrap (deprecated)
make lint        # Run linter
make format      # Format code
make test       # Run tests
make check      # Lint + test
make pre-commit-install  # Install pre-commit hooks
make pre-commit # Run pre-commit hooks
```

## Symlink Migration

The engine supports migrating symlinks from old directory structure to new `modules/` structure:

```bash
# Preview changes
uv run python -m engine.cli symlinks-diff

# Verify targets exist
uv run python -m engine.cli symlinks-verify-targets

# Execute migration (creates backup first)
uv run python -m engine.cli symlinks-migrate

# Rollback if needed
uv run python -m engine.cli symlinks-rollback
```

## Legacy Installation (Deprecated)

> **Warning**: The legacy installation method is deprecated. Use the new engine commands above instead.

The old method used shell scripts that are no longer maintained:

```bash
# DEPRECATED - Use instead:
#   uv run python -m engine.cli gitconfig
#   uv run python -m engine.cli install
#   uv run python -m engine.cli symlinks --create --verify --prune

# Old method (no longer supported)
python3 -m scripts.bootstrap  # Setup git config + symlinks
./scripts/install            # Run all install scripts
```
