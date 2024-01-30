#!/usr/bin/env bash
# i3-rofi-system-actions
# Use rofi to call systemctl for shutdown, reboot, etc
# Taken from https://github.com/orestisfl/dotfiles/blob/b2a0c96034f9a837389322e33ee176706f895b13/executables/bin/i3-rofi-actions
set -e

declare -A options
declare -a options_order

function add_option_if_file(){
    if [ -f "$2" ]
    then
        add_option "$1" "$2"
    fi
}

function add_option() {
    local option_text="$1 ($2)"

    options["$option_text"]="$2"
    options_order+=("$option_text")
}

# Fill options.
# add_option_if_file "Toggle screens" "$HOME/.screenlayout/toggle-radeon.sh"
# add_option_if_file "Rename workspace" "$HOME/bin/i3-workspace-rename.py"
add_option "Shut down system" "systemctl poweroff"
add_option "Restart system" "systemctl reboot"
add_option "Sleep monitor" "xset dpms force suspend; sleep 0.1; xset dpms force suspend"
add_option_if_file "Lock" "$HOME/bin/lock.sh"
add_option "Suspend system" "systemctl suspend"
add_option "Exit i3" "i3-msg exit"
# add_option "Hibernate" "systemctl hibernate"
options_keys=$(printf '%s\n' "${options_order[@]}")  # Get keys as a string, seperated by newlines.
options_len=$(echo -e "$options_keys"|wc -l)
echo -e "$options_keys"

launcher="rofi -matching fuzzy -l $options_len -dmenu -i -p 'System'"
selection=$(echo -e "$options_keys" | eval "$launcher" | tr -d '\r\n')
echo "$selection : ${options[$selection]}"

eval "${options[$selection]}"

