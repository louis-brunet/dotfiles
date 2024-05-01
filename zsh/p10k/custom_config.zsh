# POWERLEVEL9K_CONFIG_FILE is set in $DOTFILES/zsh/path.zsh
local generated_p10k_config="$POWERLEVEL9K_CONFIG_FILE"
if [[ ! -f "$generated_p10k_config" ]]; then
    echo '[p10k/custom_config.zsh] could not find generated p10k config' >&2
    exit 1
fi
source "$generated_p10k_config"

local black=0
local red=1
local green=2
local yellow=3
local blue=4
local magenta=5
local cyan=6
local white=7
local bright_black=8
local bright_red=9
local bright_green=10
local bright_yellow=11
local bright_blue=12
local bright_magenta=13
local bright_cyan=14
local bright_white=15

local git_meta_color=$bright_black
local git_clean_color=$green
local git_modified_color=$yellow
local git_untracked_color=$blue
local git_conflicted_color=$red
local decoration_color=$bright_black

config_general_style() {
    typeset -g POWERLEVEL9K_BACKGROUND=           # transparent background
    # typeset -g POWERLEVEL9K_DIR_BACKGROUND=$decoration_color
    typeset -g POWERLEVEL9K_DIR_FOREGROUND=$blue
    typeset -g POWERLEVEL9K_DIR_ANCHOR_FOREGROUND=$bright_blue
    # typeset -g POWERLEVEL9K_VCS_BACKGROUND=
    # typeset -g POWERLEVEL9K_BATTERY_BACKGROUND=
    # typeset -g POWERLEVEL9K_TIME_BACKGROUND=


    # typeset -g POWERLEVEL9K_LEFT_SUBSEGMENT_SEPARATOR=''
    typeset -g POWERLEVEL9K_RIGHT_SUBSEGMENT_SEPARATOR=''
    # typeset -g POWERLEVEL9K_LEFT_SEGMENT_SEPARATOR='\uE0B4 '
    # typeset -g POWERLEVEL9K_LEFT_PROMPT_FIRST_SEGMENT_START_SYMBOL='\uE0B6' # '🮊' # '🮉' # '▐' #'\uE0B6'
    # typeset -g POWERLEVEL9K_LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL='\uE0B4'
    typeset -g POWERLEVEL9K_RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL=''
    typeset -g POWERLEVEL9K_RIGHT_PROMPT_LAST_SEGMENT_END_SYMBOL=''


    # Add an empty line before each prompt.
    typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=false

    # Green prompt symbol if the last command succeeded.
    typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=$green
    # Red prompt symbol if the last command failed.
    typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=$red

    typeset -g POWERLEVEL9K_STATUS_OK_FOREGROUND=$green
    typeset -g POWERLEVEL9K_STATUS_OK_PIPE_FOREGROUND=$green
    typeset -g POWERLEVEL9K_STATUS_ERROR_FOREGROUND=$red
    typeset -g POWERLEVEL9K_STATUS_ERROR_SIGNAL_FOREGROUND=$red
    typeset -g POWERLEVEL9K_STATUS_ERROR_PIPE_FOREGROUND=$red

    typeset -g POWERLEVEL9K_BATTERY_LOW_FOREGROUND=$red
    typeset -g POWERLEVEL9K_BATTERY_{CHARGING,CHARGED}_FOREGROUND=$green
    typeset -g POWERLEVEL9K_BATTERY_DISCONNECTED_FOREGROUND=$yellow

    # Ruler, a.k.a. the horizontal line before each prompt. If you set it to true, you'll
    # probably want to set POWERLEVEL9K_PROMPT_ADD_NEWLINE=false above and
    # POWERLEVEL9K_MULTILINE_FIRST_PROMPT_GAP_CHAR=' ' below.
    # typeset -g POWERLEVEL9K_SHOW_RULER=true
    # typeset -g POWERLEVEL9K_RULER_CHAR='' # '─'       # reasonable alternative: '·'
    # typeset -g POWERLEVEL9K_RULER_FOREGROUND=237
    # typeset -g POWERLEVEL9K_RULER_BACKGROUND=

    # typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX="A"
    # typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX_FOREGROUND=$decoration_color


    # Connect left prompt lines with these symbols. You'll probably want to use the same color
    # as POWERLEVEL9K_MULTILINE_FIRST_PROMPT_GAP_FOREGROUND below.
    typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX= #'%'$decoration_color'F┏' #╭─'
    typeset -g POWERLEVEL9K_MULTILINE_NEWLINE_PROMPT_PREFIX=' ' # '%'$decoration_color'F┃ ' # 'F┗━'
    typeset -g POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX=' ' # '%'$decoration_color'F┗ ' #╭─'
    # Connect right prompt lines with these symbols.
    typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_SUFFIX= #'%'$decoration_color'F┓'
    typeset -g POWERLEVEL9K_MULTILINE_NEWLINE_PROMPT_SUFFIX= #'%'$decoration_color'F┃' # ━┫'
    typeset -g POWERLEVEL9K_MULTILINE_LAST_PROMPT_SUFFIX= #'%'$decoration_color'F┃' # ━┛'

    # Filler between left and right prompt on the first prompt line. You can set it to ' ', '·' or
    # '─'. The last two make it easier to see the alignment between left and right prompt and to
    # separate prompt from command output. You might want to set POWERLEVEL9K_PROMPT_ADD_NEWLINE=false
    # for more compact prompt if using this option.
    typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_GAP_CHAR='━' #''
    typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_GAP_BACKGROUND=
    typeset -g POWERLEVEL9K_MULTILINE_NEWLINE_PROMPT_GAP_BACKGROUND=
    if [[ $POWERLEVEL9K_MULTILINE_FIRST_PROMPT_GAP_CHAR != ' ' ]]; then
        # The color of the filler. You'll probably want to match the color of POWERLEVEL9K_MULTILINE
        # ornaments defined above.
        typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_GAP_FOREGROUND=$decoration_color
        # Start filler from the edge of the screen if there are no left segments on the first line.
        typeset -g POWERLEVEL9K_EMPTY_LINE_LEFT_PROMPT_FIRST_SEGMENT_END_SYMBOL='%{%}'
        # End filler on the edge of the screen if there are no right segments on the first line.
        typeset -g POWERLEVEL9K_EMPTY_LINE_RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL='%{%}'
    fi
}

config_segment_layout() {
    # The list of segments shown on the left. Fill it with the most important segments.
    typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
      newline
      # =========================[ Line #1 ]=========================
      os_icon                 # os identifier
      dir                     # current directory
      vcs                     # git status
      # =========================[ Line #2 ]=========================
      newline                 # \n
      prompt_char             # prompt symbol
    )
    # The list of segments shown on the right. Fill it with less important segments.
    # Right prompt on the last prompt line (where you are typing your commands) gets
    # automatically hidden when the input line reaches it. Right prompt above the
    # last prompt line gets hidden if it would overlap with left prompt.
    typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
      newline
      # =========================[ Line #1 ]=========================
      status                  # exit code of the last command
      command_execution_time  # duration of the last command
      background_jobs         # presence of background jobs
      # direnv                  # direnv status (https://direnv.net/)
      # asdf                    # asdf version manager (https://github.com/asdf-vm/asdf)
      # virtualenv              # python virtual environment (https://docs.python.org/3/library/venv.html)
      # anaconda                # conda environment (https://conda.io/)
      pyenv                   # python environment (https://github.com/pyenv/pyenv)
      # goenv                   # go environment (https://github.com/syndbg/goenv)
      nodenv                  # node.js version from nodenv (https://github.com/nodenv/nodenv)
      nvm                     # node.js version from nvm (https://github.com/nvm-sh/nvm)
      nodeenv                 # node.js environment (https://github.com/ekalinin/nodeenv)
      # node_version          # node.js version
      # go_version            # go version (https://golang.org)
      # rust_version          # rustc version (https://www.rust-lang.org)
      # dotnet_version        # .NET version (https://dotnet.microsoft.com)
      # php_version           # php version (https://www.php.net/)
      # laravel_version       # laravel php framework version (https://laravel.com/)
      # java_version          # java version (https://www.java.com/)
      package               # name@version from package.json (https://docs.npmjs.com/files/package.json)
      # rbenv                   # ruby version from rbenv (https://github.com/rbenv/rbenv)
      # rvm                     # ruby version from rvm (https://rvm.io)
      # fvm                     # flutter version management (https://github.com/leoafarias/fvm)
      # luaenv                  # lua version from luaenv (https://github.com/cehoffman/luaenv)
      # jenv                    # java version from jenv (https://github.com/jenv/jenv)
      # plenv                   # perl version from plenv (https://github.com/tokuhirom/plenv)
      # perlbrew                # perl version from perlbrew (https://github.com/gugod/App-perlbrew)
      # phpenv                  # php version from phpenv (https://github.com/phpenv/phpenv)
      # scalaenv                # scala version from scalaenv (https://github.com/scalaenv/scalaenv)
      # haskell_stack           # haskell version from stack (https://haskellstack.org/)
      # kubecontext             # current kubernetes context (https://kubernetes.io/)
      terraform               # terraform workspace (https://www.terraform.io)
      # terraform_version     # terraform version (https://www.terraform.io)
      aws                     # aws profile (https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html)
      # aws_eb_env              # aws elastic beanstalk environment (https://aws.amazon.com/elasticbeanstalk/)
      azure                   # azure account name (https://docs.microsoft.com/en-us/cli/azure)
      gcloud                  # google cloud cli account and project (https://cloud.google.com/)
      google_app_cred         # google application credentials (https://cloud.google.com/docs/authentication/production)
      # toolbox                 # toolbox name (https://github.com/containers/toolbox)
      context                 # user@hostname
      # nordvpn                 # nordvpn connection status, linux only (https://nordvpn.com/)
      # ranger                  # ranger shell (https://github.com/ranger/ranger)
      # yazi                    # yazi shell (https://github.com/sxyazi/yazi)
      # nnn                     # nnn shell (https://github.com/jarun/nnn)
      # lf                      # lf shell (https://github.com/gokcehan/lf)
      # xplr                    # xplr shell (https://github.com/sayanarijit/xplr)
      vim_shell               # vim shell indicator (:sh)
      # midnight_commander      # midnight commander shell (https://midnight-commander.org/)
      # nix_shell               # nix shell (https://nixos.org/nixos/nix-pills/developing-with-nix-shell.html)
      # chezmoi_shell           # chezmoi shell (https://www.chezmoi.io/)
      # vi_mode               # vi mode (you don't need this if you've enabled prompt_char)
      # vpn_ip                # virtual private network indicator
      # load                  # CPU load
      # disk_usage            # disk usage
      # ram                   # free RAM
      # swap                  # used swap
      # todo                    # todo items (https://github.com/todotxt/todo.txt-cli)
      # timewarrior             # timewarrior tracking status (https://timewarrior.net/)
      # taskwarrior             # taskwarrior task count (https://taskwarrior.org/)
      # per_directory_history   # Oh My Zsh per-directory-history local/global indicator
      # cpu_arch              # CPU architecture
      time                    # current time
      # =========================[ Line #2 ]=========================
      newline                 # \n
      # ip                    # ip address and bandwidth usage for a specified network interface
      # public_ip             # public IP address
      # proxy                 # system-wide http/https/ftp proxy
      battery               # internal battery
      # wifi                  # wifi speed
      # example               # example user-defined segment (see prompt_example function below)
    )
}

config_git() {
  #####################################[ vcs: git status ]######################################
  # Branch icon. Set this parameter to '\UE0A0 ' for the popular Powerline branch icon.
  typeset -g POWERLEVEL9K_VCS_BRANCH_ICON=

  # Untracked files icon. It's really a question mark, your font isn't broken.
  # Change the value of this parameter to show a different icon.
  typeset -g POWERLEVEL9K_VCS_UNTRACKED_ICON='?'

  # Formatter for Git status.
  #
  # Example output: master wip ⇣42⇡42 *42 merge ~42 +42 !42 ?42.
  #
  # You can edit the function to customize how Git status looks.
  #
  # VCS_STATUS_* parameters are set by gitstatus plugin. See reference:
  # https://github.com/romkatv/gitstatus/blob/master/gitstatus.plugin.zsh.
  function my_git_formatter() {
    emulate -L zsh

    if [[ -n $P9K_CONTENT ]]; then
      # If P9K_CONTENT is not empty, use it. It's either "loading" or from vcs_info (not from
      # gitstatus plugin). VCS_STATUS_* parameters are not available in this case.
      typeset -g my_git_format=$P9K_CONTENT
      return
    fi

    if (( $1 )); then
      # Styling for up-to-date Git status.
      local       meta='%'$git_meta_color'F'  # grey foreground
      local      clean='%'$git_clean_color'F'   # green foreground
      local   modified='%'$git_modified_color'F'  # yellow foreground
      local  untracked='%'$git_untracked_color'F'   # blue foreground
      local conflicted='%'$git_conflicted_color'F'  # red foreground
    else
      # Styling for incomplete and stale Git status.
      local       meta='%244F'  # grey foreground
      local      clean='%244F'  # grey foreground
      local   modified='%244F'  # grey foreground
      local  untracked='%244F'  # grey foreground
      local conflicted='%244F'  # grey foreground
    fi

    local res

    if [[ -n $VCS_STATUS_LOCAL_BRANCH ]]; then
      local branch=${(V)VCS_STATUS_LOCAL_BRANCH}
      # If local branch name is at most 32 characters long, show it in full.
      # Otherwise show the first 12 … the last 12.
      # Tip: To always show local branch name in full without truncation, delete the next line.
      (( $#branch > 32 )) && branch[13,-13]="…"  # <-- this line
      res+="${clean}${(g::)POWERLEVEL9K_VCS_BRANCH_ICON}${branch//\%/%%}"
    fi

    if [[ -n $VCS_STATUS_TAG
          # Show tag only if not on a branch.
          # Tip: To always show tag, delete the next line.
          && -z $VCS_STATUS_LOCAL_BRANCH  # <-- this line
        ]]; then
      local tag=${(V)VCS_STATUS_TAG}
      # If tag name is at most 32 characters long, show it in full.
      # Otherwise show the first 12 … the last 12.
      # Tip: To always show tag name in full without truncation, delete the next line.
      (( $#tag > 32 )) && tag[13,-13]="…"  # <-- this line
      res+="${meta}#${clean}${tag//\%/%%}"
    fi

    # Display the current Git commit if there is no branch and no tag.
    # Tip: To always display the current Git commit, delete the next line.
    [[ -z $VCS_STATUS_LOCAL_BRANCH && -z $VCS_STATUS_TAG ]] &&  # <-- this line
      res+="${meta}@${clean}${VCS_STATUS_COMMIT[1,8]}"

    # Show tracking branch name if it differs from local branch.
    if [[ -n ${VCS_STATUS_REMOTE_BRANCH:#$VCS_STATUS_LOCAL_BRANCH} ]]; then
      res+="${meta}:${clean}${(V)VCS_STATUS_REMOTE_BRANCH//\%/%%}"
    fi

    # Display "wip" if the latest commit's summary contains "wip" or "WIP".
    if [[ $VCS_STATUS_COMMIT_SUMMARY == (|*[^[:alnum:]])(wip|WIP)(|[^[:alnum:]]*) ]]; then
      res+=" ${modified}wip"
    fi

    if (( VCS_STATUS_COMMITS_AHEAD || VCS_STATUS_COMMITS_BEHIND )); then
      # ⇣42 if behind the remote.
      (( VCS_STATUS_COMMITS_BEHIND )) && res+=" ${clean}⇣${VCS_STATUS_COMMITS_BEHIND}"
      # ⇡42 if ahead of the remote; no leading space if also behind the remote: ⇣42⇡42.
      (( VCS_STATUS_COMMITS_AHEAD && !VCS_STATUS_COMMITS_BEHIND )) && res+=" "
      (( VCS_STATUS_COMMITS_AHEAD  )) && res+="${clean}⇡${VCS_STATUS_COMMITS_AHEAD}"
    elif [[ -n $VCS_STATUS_REMOTE_BRANCH ]]; then
      # Tip: Uncomment the next line to display '=' if up to date with the remote.
      # res+=" ${clean}="
    fi

    # ⇠42 if behind the push remote.
    (( VCS_STATUS_PUSH_COMMITS_BEHIND )) && res+=" ${clean}⇠${VCS_STATUS_PUSH_COMMITS_BEHIND}"
    (( VCS_STATUS_PUSH_COMMITS_AHEAD && !VCS_STATUS_PUSH_COMMITS_BEHIND )) && res+=" "
    # ⇢42 if ahead of the push remote; no leading space if also behind: ⇠42⇢42.
    (( VCS_STATUS_PUSH_COMMITS_AHEAD  )) && res+="${clean}⇢${VCS_STATUS_PUSH_COMMITS_AHEAD}"
    # *42 if have stashes.
    (( VCS_STATUS_STASHES        )) && res+=" ${clean}*${VCS_STATUS_STASHES}"
    # 'merge' if the repo is in an unusual state.
    [[ -n $VCS_STATUS_ACTION     ]] && res+=" ${conflicted}${VCS_STATUS_ACTION}"
    # ~42 if have merge conflicts.
    (( VCS_STATUS_NUM_CONFLICTED )) && res+=" ${conflicted}~${VCS_STATUS_NUM_CONFLICTED}"
    # +42 if have staged changes.
    (( VCS_STATUS_NUM_STAGED     )) && res+=" ${modified}+${VCS_STATUS_NUM_STAGED}"
    # !42 if have unstaged changes.
    (( VCS_STATUS_NUM_UNSTAGED   )) && res+=" ${modified}!${VCS_STATUS_NUM_UNSTAGED}"
    # ?42 if have untracked files. It's really a question mark, your font isn't broken.
    # See POWERLEVEL9K_VCS_UNTRACKED_ICON above if you want to use a different icon.
    # Remove the next line if you don't want to see untracked files at all.
    (( VCS_STATUS_NUM_UNTRACKED  )) && res+=" ${untracked}${(g::)POWERLEVEL9K_VCS_UNTRACKED_ICON}${VCS_STATUS_NUM_UNTRACKED}"
    # "─" if the number of unstaged files is unknown. This can happen due to
    # POWERLEVEL9K_VCS_MAX_INDEX_SIZE_DIRTY (see below) being set to a non-negative number lower
    # than the number of files in the Git index, or due to bash.showDirtyState being set to false
    # in the repository config. The number of staged and untracked files may also be unknown
    # in this case.
    (( VCS_STATUS_HAS_UNSTAGED == -1 )) && res+=" ${modified}─"

    typeset -g my_git_format=$res
  }
  functions -M my_git_formatter 2>/dev/null

  # Don't count the number of unstaged, untracked and conflicted files in Git repositories with
  # more than this many files in the index. Negative value means infinity.
  #
  # If you are working in Git repositories with tens of millions of files and seeing performance
  # sagging, try setting POWERLEVEL9K_VCS_MAX_INDEX_SIZE_DIRTY to a number lower than the output
  # of `git ls-files | wc -l`. Alternatively, add `bash.showDirtyState = false` to the repository's
  # config: `git config bash.showDirtyState false`.
  typeset -g POWERLEVEL9K_VCS_MAX_INDEX_SIZE_DIRTY=-1

  # Don't show Git status in prompt for repositories whose workdir matches this pattern.
  # For example, if set to '~', the Git repository at $HOME/.git will be ignored.
  # Multiple patterns can be combined with '|': '~(|/foo)|/bar/baz/*'.
  typeset -g POWERLEVEL9K_VCS_DISABLED_WORKDIR_PATTERN='~'

  # Disable the default Git status formatting.
  typeset -g POWERLEVEL9K_VCS_DISABLE_GITSTATUS_FORMATTING=true
  # Install our own Git status formatter.
  typeset -g POWERLEVEL9K_VCS_CONTENT_EXPANSION='${$((my_git_formatter(1)))+${my_git_format}}'
  typeset -g POWERLEVEL9K_VCS_LOADING_CONTENT_EXPANSION='${$((my_git_formatter(0)))+${my_git_format}}'
  # Enable counters for staged, unstaged, etc.
  typeset -g POWERLEVEL9K_VCS_{STAGED,UNSTAGED,UNTRACKED,CONFLICTED,COMMITS_AHEAD,COMMITS_BEHIND}_MAX_NUM=-1

  # Icon color.
  typeset -g POWERLEVEL9K_VCS_VISUAL_IDENTIFIER_COLOR=$green
  typeset -g POWERLEVEL9K_VCS_LOADING_VISUAL_IDENTIFIER_COLOR=244
  # Custom icon.
  typeset -g POWERLEVEL9K_VCS_VISUAL_IDENTIFIER_EXPANSION=
  # Custom prefix.
  # typeset -g POWERLEVEL9K_VCS_PREFIX='%246Fon '

  # Show status of repositories of these types. You can add svn and/or hg if you are
  # using them. If you do, your prompt may become slow even when your current directory
  # isn't in an svn or hg reposotiry.
  typeset -g POWERLEVEL9K_VCS_BACKENDS=(git)

  # These settings are used for repositories other than Git or when gitstatusd fails and
  # Powerlevel10k has to fall back to using vcs_info.
  typeset -g POWERLEVEL9K_VCS_CLEAN_FOREGROUND=$green
  typeset -g POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND=$green
  typeset -g POWERLEVEL9K_VCS_MODIFIED_FOREGROUND=$yellow
}

config_general_style
config_segment_layout
config_git


