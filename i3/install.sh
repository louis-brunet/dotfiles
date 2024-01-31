#!/usr/bin/env bash


set -e 
sudo apt-get install -y i3
i3 --version
echo "✅ installed i3 window manager, log out and back in if needed"

# Install playerctl for media keybinds (pause, play, stop)
if ! which playerctl; then
    playerctl_download_path=$HOME/Downloads/playerctl.deb
    curl -o "$playerctl_download_path" -L https://github.com/altdesktop/playerctl/releases/download/v2.4.1/playerctl-2.4.1_amd64.deb
    sudo dpkg -i "$playerctl_download_path"

    playerctl --version
    echo "✅ installed playerctl for media keys in i3"
else
    playerctl --version
    echo "✅ playerctl already installed, skipping"
fi 

# arandr: GUI to generate xrandr commands for a multi-monitor setup
# compton: window compositor for transparency & other effects
# i3blocks: status bar
# pulseaudio-utils (command: pactl): Control a running PulseAudio sound server
# polybar: status bar
# rofi: A window switcher, Application launcher and dmenu replacement. https://github.com/davatorium/rofi
sudo apt-get install -y \
    arandr \
    compton \
    pulseaudio-utils \
    polybar \
    rofi 
    # i3blocks \
echo "✅ installed arandr, compton, pactl and rofi for i3"

