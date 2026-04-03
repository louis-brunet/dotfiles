"""Gitconfig command."""

import argparse
import os
import subprocess
import sys
from pathlib import Path

from ..console import get_console
from ..module import discover_modules


def run(args: argparse.Namespace) -> None:
    """Setup git local config."""
    console = get_console()
    dotfiles_root = Path(args.dotfiles_root).resolve()
    modules_dir = dotfiles_root / "modules"

    modules = discover_modules(modules_dir)
    git_module = modules.get("git")

    if git_module is None:
        console.error("Git module not found in modules/git/")
        sys.exit(1)

    gitconfig_path = git_module.path / "gitconfig.local"
    gitconfig_template = git_module.path / "gitconfig.local.template"

    if gitconfig_path.exists():
        console.info(f"Git config already exists at {gitconfig_path}")
        if not args.force:
            return

    if not gitconfig_template.exists():
        console.error(f"Template not found: {gitconfig_template}")
        sys.exit(1)

    if args.name is None:
        console.print_inline("Enter git author name: ")
        try:
            name = input().strip()
        except EOFError:
            console.error("Input required")
            sys.exit(1)
        if not name:
            console.error("Name is required")
            sys.exit(1)
    else:
        name = args.name

    if args.email is None:
        console.print_inline("Enter git author email: ")
        try:
            email = input().strip()
        except EOFError:
            console.error("Input required")
            sys.exit(1)
        if not email:
            console.error("Email is required")
            sys.exit(1)
    else:
        email = args.email

    signing_key = ""
    gpg_sign = "false"
    gpg_format = "ssh"

    xdg_config = os.environ.get("XDG_CONFIG_HOME", os.path.expanduser("~/.config"))
    allowed_signers_file = os.path.join(xdg_config, "git", "allowed_signers_file")

    default_ssh_key = os.path.expanduser("~/.ssh/id_ed25519.pub")
    if os.path.exists(default_ssh_key):
        signing_key = default_ssh_key

    console.print_inline("Sign commits? [Y/n]: ")
    try:
        response = input().strip().lower()
    except EOFError:
        response = "y"

    if response in ("", "y", "yes"):
        console.print_inline("Key format (ssh/openpgp) [ssh]: ")
        try:
            format_response = input().strip().lower()
        except EOFError:
            format_response = "ssh"

        if format_response in ("", "ssh"):
            gpg_format = "ssh"
            console.print_inline(f"SSH signing key [{signing_key}]: ")
            try:
                key_response = input().strip()
            except EOFError:
                key_response = ""

            if key_response:
                signing_key = key_response

            if signing_key and not os.path.exists(signing_key):
                console.error(f"Signing key not found: {signing_key}")
                sys.exit(1)

            if signing_key:
                console.print_inline(f"Allowed signers file [{allowed_signers_file}]: ")
                try:
                    signers_response = input().strip()
                except EOFError:
                    signers_response = ""

                if signers_response:
                    allowed_signers_file = signers_response

                if not os.path.exists(os.path.dirname(allowed_signers_file)):
                    os.makedirs(os.path.dirname(allowed_signers_file), exist_ok=True)

                with open(signing_key) as f:
                    key_content = f.read().strip()

                signer_line = f"{email} {key_content}"
                if os.path.exists(allowed_signers_file):
                    with open(allowed_signers_file) as f:
                        existing = f.read()
                    if signer_line not in existing:
                        console.print_inline("Add to allowed signers? [Y/n]: ")
                        try:
                            add_response = input().strip().lower()
                        except EOFError:
                            add_response = "y"
                        if add_response in ("", "y", "yes"):
                            with open(allowed_signers_file, "a") as f:
                                f.write(f"{signer_line}\n")
                            console.success("Added to allowed signers")
                        else:
                            console.warning("Skipped adding to allowed signers")
                else:
                    with open(allowed_signers_file, "w") as f:
                        f.write(f"{signer_line}\n")
                    console.success("Created allowed signers file")
        else:
            gpg_format = "openpgp"
            console.print_inline("GPG key ID: ")
            try:
                signing_key = input().strip()
            except EOFError:
                signing_key = ""

        if signing_key:
            gpg_sign = "true"

    config_values = {
        "AUTHORNAME": name,
        "AUTHOREMAIL": email,
        "GIT_CREDENTIAL_HELPER": "cache",
        "SIGNING_KEY": signing_key,
        "GPG_SIGN": gpg_sign,
        "GPG_FORMAT": gpg_format,
        "GPG_SSH_ALLOWED_SIGNERS_FILE": allowed_signers_file,
    }

    sed_args = []
    for key, value in config_values.items():
        escaped_value = value.replace("/", r"\/")
        sed_args.extend(["-e", f"s:{key}:{escaped_value}:g"])

    result = subprocess.run(
        ["sed", *sed_args, str(gitconfig_template)],
        capture_output=True,
        text=True,
    )

    if result.returncode != 0:
        console.error(f"sed failed: {result.stderr}")
        sys.exit(1)

    gitconfig_path.write_text(result.stdout)
    console.success(f"Created {gitconfig_path}")
    console.info("Run 'dotfiles symlinks --create --verify --prune' to link it")


def add_parser(subparsers) -> argparse.ArgumentParser:
    parser = subparsers.add_parser("gitconfig", help="Setup git local config")
    parser.add_argument("--dotfiles-root", default=".", help="Dotfiles root directory")
    parser.add_argument("--name", "-n", help="Git author name")
    parser.add_argument("--email", "-e", help="Git author email")
    parser.add_argument("--force", "-f", action="store_true", help="Overwrite existing config")
    parser.set_defaults(func=run)
    return parser
