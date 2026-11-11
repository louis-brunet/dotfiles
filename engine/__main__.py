#!/usr/bin/env python3
"""
Entry point for the dotfiles engine.

When run as a module (python -m engine), this delegates to the CLI.
"""


def main():
    """Entry point that delegates to the CLI."""
    from engine.cli import main as cli_main

    cli_main()


if __name__ == "__main__":
    main()
