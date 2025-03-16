import argparse
import logging
import os.path
import subprocess
import sys
import shutil
from typing import NoReturn, TypedDict
from .colored_logger import (
    prompt_required,
    prompt_yes_no,
    setup_colored_logging,
)


class GitConfig(TypedDict):
    AUTHORNAME: str
    AUTHOREMAIL: str
    GIT_CREDENTIAL_HELPER: str
    SIGNING_KEY: str | None
    GPG_SIGN: str
    GPG_FORMAT: str
    GPG_SSH_ALLOWED_SIGNERS_FILE: str


class ProgramArguments(TypedDict):
    git_author_name: str
    git_author_email: str


module_logger = logging.getLogger("bootstrap")


def die(message: str, logger=module_logger) -> NoReturn:
    logger.critical(message)
    sys.exit(1)


def expand_path(*path_parts: str) -> str:
    return os.path.join(*[os.path.expandvars(path_part) for path_part in path_parts])


def expand_env_var_or_default_path(var_name: str, *default_path: str) -> str:
    """Get an environment variable's value if is exists, otherwise expand the
    given default value with expandvar().

    Args:
        var_name: an environment variable name
        default_path: given to os.path.expandvars()
    """
    env_value = os.environ.get(var_name)
    if not env_value:
        return os.path.expandvars(os.path.join(*default_path))
    return env_value


def configure_git_ssh_allowed_signers(config_values: GitConfig) -> None:
    logger = module_logger.getChild(configure_git_ssh_allowed_signers.__name__)
    # Create the allowed signer line from the author email and the contents of the signing key file
    git_authoremail = config_values["AUTHOREMAIL"]
    signing_key_file = config_values["SIGNING_KEY"]
    assert signing_key_file is not None

    with open(signing_key_file, "r") as f:
        signing_key_content = f.read().strip()

    new_allowed_signer_line = f"{git_authoremail} {signing_key_content}"

    # Check if the line already exists in the allowed signers file
    signer_file_exists = os.path.isfile(config_values["GPG_SSH_ALLOWED_SIGNERS_FILE"])
    line_exists = False

    if signer_file_exists:
        with open(config_values["GPG_SSH_ALLOWED_SIGNERS_FILE"], "r") as f:
            content = f.read()
            line_exists = new_allowed_signer_line in content.splitlines()

    if not line_exists:
        prompt_text = (
            f"git: add the following line to the file '{config_values['GPG_SSH_ALLOWED_SIGNERS_FILE']}'?\n"
            f"{new_allowed_signer_line}\n"
        )
        if prompt_yes_no(prompt_text, default=True):
            # Create directory if it doesn't exist
            os.makedirs(
                os.path.dirname(config_values["GPG_SSH_ALLOWED_SIGNERS_FILE"]),
                exist_ok=True,
            )

            # Add the line to the file
            with open(config_values["GPG_SSH_ALLOWED_SIGNERS_FILE"], "a") as f:
                f.write(f"{new_allowed_signer_line}\n")

            logger.info(
                f"Success: added signing key '{config_values['SIGNING_KEY']}' to '{config_values['GPG_SSH_ALLOWED_SIGNERS_FILE']}'"
            )
    else:
        logger.info(
            f"Success: signing key '{config_values['SIGNING_KEY']}' is registered in '{config_values['GPG_SSH_ALLOWED_SIGNERS_FILE']}'"
        )


def configure_commit_signature(config_values: GitConfig) -> None:
    config_values["GPG_SIGN"] = "true"

    config_values["GPG_FORMAT"] = prompt_required(
        "git: commit signature key format (ssh, openpgp)",
        default=config_values["GPG_FORMAT"],
    )
    if config_values["GPG_FORMAT"] == "ssh":
        config_values["SIGNING_KEY"] = prompt_required(
            "git: path to the SSH public key for commit signature",
            default=config_values["SIGNING_KEY"],
        )
        if not os.path.isfile(config_values["SIGNING_KEY"]):
            raise ValueError(
                f"could not find SSH key file at '{config_values['SIGNING_KEY']}'"
            )

        config_values["GPG_SSH_ALLOWED_SIGNERS_FILE"] = prompt_required(
            "git: path to the file containing allowed signers' public keys and their committer emails",
            default=config_values["GPG_SSH_ALLOWED_SIGNERS_FILE"],
        )

        configure_git_ssh_allowed_signers(config_values)
    elif config_values["GPG_FORMAT"] == "openpgp":
        config_values["SIGNING_KEY"] = prompt_required(
            "git: GPG key ID",
        )
    else:
        raise ValueError(
            f"unrecognized GPG format value '{config_values['GPG_FORMAT']}'"
        )


def create_local_gitconfig(
    local_gitconfig_path: str,
    local_gitconfig_template_path: str,
    git_author_name: str | None,
    git_author_email: str | None,
) -> None:
    logger = module_logger.getChild(create_local_gitconfig.__name__)
    default_signers_file = os.path.join(
        expand_env_var_or_default_path("XDG_CONFIG_HOME", "$HOME", ".config"),
        "git",
        "allowed_signers_file",
    )
    config_values: GitConfig = {
        "AUTHORNAME": git_author_name or prompt_required("git: author name"),
        "AUTHOREMAIL": git_author_email or prompt_required("git: author email"),
        "GIT_CREDENTIAL_HELPER": "cache",
        "SIGNING_KEY": None,
        "GPG_SIGN": "false",
        "GPG_FORMAT": "ssh",
        "GPG_SSH_ALLOWED_SIGNERS_FILE": default_signers_file,
    }

    default_ssh_signing_key = expand_path("$HOME", ".ssh", "id_ed25519.pub")
    if os.path.exists(default_ssh_signing_key):
        config_values["SIGNING_KEY"] = default_ssh_signing_key

    if prompt_yes_no("git: sign commits?", default=True):
        configure_commit_signature(config_values)

    sed_args = [
        new_arg
        for config_key in config_values
        for new_arg in ["-e", f"s:{config_key}:{config_values[config_key]}:g"]
    ]
    call_command = [
        "sh",
        "-c",
        f"{subprocess.list2cmdline(['sed', *sed_args, local_gitconfig_template_path])} >'{local_gitconfig_path}'",
    ]
    sed_result = subprocess.check_call(call_command)
    if sed_result != 0:
        die("sed failed", logger=logger)

    logger.info("local gitconfig successfully set up")


def setup_gitconfig(
    git_author_name: str | None,
    git_author_email: str | None,
):
    logger = module_logger.getChild(setup_gitconfig.__name__)
    local_gitconfig_path = os.path.join("git", "gitconfig.local")
    local_gitconfig_template_path = f"{local_gitconfig_path}.template"

    if os.path.exists(local_gitconfig_path):
        logger.info("local gitconfig file already exists")
        return

    logger.info("need to create local gitconfig file")
    if not os.path.isfile(local_gitconfig_template_path):
        die(
            f"could not find local gitconfig template '{local_gitconfig_template_path}'",
            logger=logger,
        )
    create_local_gitconfig(
        local_gitconfig_path=local_gitconfig_path,
        local_gitconfig_template_path=local_gitconfig_template_path,
        git_author_name=git_author_name,
        git_author_email=git_author_email,
    )

    # die("TODO", logger=logger)


def setup_symlinks(dotfiles_root: str):
    logger = module_logger.getChild(setup_symlinks.__name__)
    symlonk_executable = "symlonk"
    if not shutil.which(symlonk_executable):
        die(
            "could not find symlonk executable: install https://github.com/louis-brunet/symlonk"
        )

    subprocess.check_call(
        [
            "sh",
            "-c",
            subprocess.list2cmdline(
                [
                    symlonk_executable,
                    "create",
                    "links",
                    f"{dotfiles_root}/*/symlonk.toml",
                    "--prune",
                    "--verify",
                ]
            ),
        ]
    )
    logger.info("configured symlinks")


def parse_args():
    parser = argparse.ArgumentParser(
        prog="bootstrap", description="Configure local git options and set up symlinks."
    )

    parser.add_argument("--git-author-name", required=False)
    parser.add_argument("--git-author-email", required=False)

    args = parser.parse_args()
    return ProgramArguments(
        git_author_name=args.git_author_name,
        git_author_email=args.git_author_email,
    )


def main():
    logger = module_logger.getChild(main.__name__)
    args = parse_args()

    dotfiles_root = os.path.dirname(os.path.dirname(__file__))
    os.chdir(dotfiles_root)
    logger.debug(f"set current working directory to '{dotfiles_root}'")

    setup_colored_logging()
    setup_gitconfig(
        git_author_name=args["git_author_name"],
        git_author_email=args["git_author_email"],
    )
    setup_symlinks(dotfiles_root=dotfiles_root)


if __name__ == "__main__":
    main()
