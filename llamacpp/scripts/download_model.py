#!/usr/bin/env python3

import argparse
import os
import subprocess
import sys
import shutil


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Download a model from a Hugging Face repository.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )

    parser.add_argument(
        "--hf-repo",
        type=str,
        required=True,
        help="The Hugging Face repository to process.",
    )
    parser.add_argument(
        "--hf-files",
        type=str,
        required=True,
        help="The files to process from the Hugging Face repository. Can contain '*' wildcards.'",
    )
    # parser.add_argument(
    #     "--local-dir",
    #     type=str,
    #     help="Directory where to store the downloaded files. If not provided, the files will be downloaded to the huggingface CLI's cache directory.",
    # )
    parser.add_argument(
        "--output-file-path",
        type=str,
        required=True,
        help="The path where the output model file should be stored.",
    )
    parser.add_argument(
        "--merge",
        action="store_true",
        # type=bool,
        # nargs="0",
        # default=False,
        help="Set to True if the downloaded model files need to be merged into a single file.",
    )

    return parser.parse_args()


def run_cmd(cmd_args: list[str]):
    cmd = " ".join(cmd_args)
    try:
        return subprocess.run(
            cmd,
            check=True,
            shell=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
    except subprocess.CalledProcessError as e:
        print(
            "ERROR running command '{}'. Exit code {}".format(
                " ".join(cmd_args), e.returncode
            ),
            file=sys.stderr,
        )
        print("child process STDERR:", file=sys.stderr)
        print(e.stderr, file=sys.stderr)
        sys.exit(1)


def download_model(hf_repo: str, hf_files_glob: str) -> str:
    # , local_dir: Optional[str]):

    if not hf_repo or not hf_files_glob:
        raise ValueError("hf_repo and hf_files_glob are required")

    cmd = [
        "huggingface-cli",
        "download",
        hf_repo,
        f"--include={hf_files_glob}",
    ]
    # if local_dir is not None:
    #     cmd.append(f"--local-dir={local_dir}")

    print("Running command: {}".format(" ".join(cmd)))

    run_result = run_cmd(cmd)
    downloaded_directory = run_result.stdout.decode("utf-8").strip()
    if not downloaded_directory:
        raise ValueError("Expected downloaded_directory to be non-empty")

    return downloaded_directory


def merge_model(download_dir, output_model_file_path):
    first_model_split_file = os.path.join(download_dir, "*0001-of*.gguf")
    cmd = [
        "llama-gguf-split",
        "--merge",
        first_model_split_file,
        output_model_file_path,
    ]
    run_result = run_cmd(cmd)
    return run_result


def main():
    args = parse_args()
    hf_repo: str = args.hf_repo
    hf_files: str = args.hf_files
    # local_dir: Optional[str] = args.local_dir
    output_file_path: str = args.output_file_path
    needs_merge: bool = args.merge

    downloaded_directory = download_model(hf_repo, hf_files)  # , local_dir)
    print("Downloaded files from {} to {}".format(hf_repo, downloaded_directory))

    if needs_merge:
        merge_model(downloaded_directory, output_file_path)
        print(
            "Merged model files from {} into {}".format(
                downloaded_directory, output_file_path
            )
        )
    else:
        files = os.listdir(downloaded_directory)
        if len(files) != 1:
            raise ValueError(
                "Expected one file in the downloaded directory, but found {}".format(
                    len(files)
                )
            )
        downloaded_model = os.path.join(downloaded_directory, files[0])
        shutil.copyfile(downloaded_model, output_file_path)
        print("Copied file {} to {}".format(downloaded_model, output_file_path))



if __name__ == "__main__":
    main()
