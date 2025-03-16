#!/usr/bin/env bash
#
# Initialize local git config and create symlinks in $HOME.
#
# Adapted from https://github.com/holman/dotfiles/blob/master/script/bootstrap

cd "$(dirname "$0")/.."
DOTFILES_ROOT=$(pwd -P)
GITCONFIG_FILE=git/gitconfig.local
GITCONFIG_TEMPLATE=$GITCONFIG_FILE.template

set -e

echo ''

info() {
  printf "\r  [\033[00;34minfo\033[0m] %s\n" "$*"
}

user() {
  printf "\r  [ \033[0;33m??\033[0m ] %b\n" "$*"
}

success() {
  printf "\r\033[2K  [ \033[00;32mOK\033[0m ] %s\n" "$*"
}

warn() {
  printf "\r\033[2K  [\033[0;33mWARN\033[0m] %s\n" "$*"
}

fail() {
  printf "\r\033[2K  [\033[0;31mFAIL\033[0m] %s\n" "$*"
  echo ''
  exit 1
}

setup_gitconfig() {
  if ! [ -f "$GITCONFIG_FILE" ]; then
    info 'setup gitconfig'
    if [ ! -f $GITCONFIG_TEMPLATE ]; then
      fail "could not find local gitconfig template '$GITCONFIG_TEMPLATE'"
    fi

    git_credential='cache'

    user ' - What is your git author name?'
    read -e git_authorname
    user ' - What is your git author email?'
    read -e git_authoremail

    gpg_sign=false
    gpg_format=ssh
    signing_key=
    gpg_ssh_allowed_signers_file="${XDG_CONFIG_HOME:-$HOME/.config}/git/allowed_signers_file"

    default_ssh_signing_key="$HOME/.ssh/id_ed25519.pub"
    if [[ -f "$default_ssh_signing_key" ]]; then
      signing_key="$default_ssh_signing_key"
    fi


    user ' - Sign commits? (y/N)'
    read -e sign_commits
    if [[ "$sign_commits" == 'y' ]] || [[ "$sign_commits" == 'Y' ]]; then
      gpg_sign=true

      user " - Which key format to use to sign commits? (ssh, openpgp) [$gpg_format]"
      read -e signing_key_format
      if [[ "$signing_key_format" = "" ]]; then
        signing_key_format="$gpg_format"
      fi
      if [[ "$signing_key_format" = "openpgp" ]]; then
        signing_key=""

        user " - Which GPG key ID to use to sign commits?"
        read -e signing_key
      elif [[ "$signing_key_format" = "ssh" ]]; then
        signing_key_path_prompt=" - Path to the SSH public key used to sign commits?"
        if [[ -n "$signing_key" ]]; then
          signing_key_path_prompt="$signing_key_path_prompt [$signing_key]"
        fi
        user "$signing_key_path_prompt"
        read -e signing_key_path
        if [[ "$signing_key_path" = "" ]]; then
          signing_key_path="$signing_key"
        fi
        if [[ ! -f "$signing_key_path" ]]; then
          fail "could not find SSH public key file used to sign commits at '$signing_key_path'"
        fi
        signing_key="$signing_key_path"

        user " - Path to the file containing allowed signers' public keys and their committer emails? [$gpg_ssh_allowed_signers_file]"
        read -e signers_file_path
        if [[ "$signers_file_path" = "" ]]; then
          signers_file_path="$gpg_ssh_allowed_signers_file"
        fi
        gpg_ssh_allowed_signers_file="$signers_file_path"

        # setup_git_allowed_signers "$signers_file_path" "$git_authoremail" "$signing_key_path"

        new_allowed_signer_line="$git_authoremail $(cat "$signing_key_path")"

        if ! grep -q "^$new_allowed_signer_line"'$' "$signers_file_path"; then
          user " - Add the following line to the file '$signers_file_path'? (Y/n)\n$new_allowed_signer_line"
          read -e add_new_allowed_signer_line
          if [[ ! "$add_new_allowed_signer_line" = "n" ]] && [[ ! "$add_new_allowed_signer_line" = "N" ]]; then
            mkdir -p "$(dirname "$signers_file_path")"
            echo "$new_allowed_signer_line" >>"$signers_file_path"
            success "added signing key '$signing_key_path' to '$signers_file_path'"
          fi
        else
          success "signing key '$signing_key_path' is registered in '$signers_file_path'"
        fi
      else
        fail "unrecognized key type: '$signing_key_format'"
      fi
      gpg_format="$signing_key_format"
    fi

    sed \
      -e "s/AUTHORNAME/$git_authorname/g" \
      -e "s/AUTHOREMAIL/$git_authoremail/g" \
      -e "s/GIT_CREDENTIAL_HELPER/$git_credential/g" \
      -e "s:SIGNING_KEY:$signing_key:g" \
      -e "s/GPG_SIGN/$gpg_sign/g" \
      -e "s/GPG_FORMAT/$gpg_format/g" \
      -e "s:GPG_SSH_ALLOWED_SIGNERS_FILE:$gpg_ssh_allowed_signers_file:g" \
      "$GITCONFIG_TEMPLATE" >"$GITCONFIG_FILE" || fail "could not replace local gitconfig placeholders"

    success 'gitconfig successfully set up'
  fi
}

setup_symlinks() {
  # install symlonk
  if ! which symlonk >/dev/null; then
    fail "could not find symlonk executable: install https://github.com/louis-brunet/symlonk"
  fi

  # run symlonk
  symlonk create links "$DOTFILES_ROOT"/*/symlonk.toml --prune --verify
}

sleep_seconds=5
warn 'DEPRECATED - use `python3 -m scripts.boostrap` instead.' "Sleeping for $sleep_seconds seconds..."
sleep "$sleep_seconds"

setup_gitconfig
setup_symlinks

echo ''
echo '  All installed!'
