# [[ "$LOCAL_ENV" != "neoxia" ]] ||
{
    # aws
    complete -C '/usr/local/bin/aws_completer' aws


    # terraform
    terraform_path="$(which terraform)"
    if [ -n terraform_path ]; then
        complete -o nospace -C "$terraform_path" terraform
    fi


    #compdef cdktf
    ###-begin-cdktf-completions-###
    #
    # yargs command completion script
    #
    # Installation: cdktf completion >> ~/.zshrc
    #    or cdktf completion >> ~/.zsh_profile on OSX.
    #
    _cdktf_yargs_completions()
    {
      local reply
      local si=$IFS
      IFS=$'
    ' reply=($(COMP_CWORD="$((CURRENT-1))" COMP_LINE="$BUFFER" COMP_POINT="$CURSOR" cdktf --get-yargs-completions "${words[@]}"))
      IFS=$si
      _describe 'values' reply
    }
    compdef _cdktf_yargs_completions cdktf
    ###-end-cdktf-completions-###
}
