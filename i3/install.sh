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

# Install i3blocks for the i3 status bar
if ! which i3blocks; then
    sudo apt-get install -y i3blocks
    i3blocks -V

    echo "✅ installed i3blocks for media keys in i3"
else
    i3blocks -V

    echo "✅ i3blocks already installed, skipping"
fi 

# arandr: GUI to generate xrandr commands for a multi-monitor setup
# rofi: A window switcher, Application launcher and dmenu replacement. https://github.com/davatorium/rofi
# compton: window compositor for transparency & other effects
sudo apt-get install -y arandr rofi compton
echo "✅ installed arandr, rofi and compton for i3"

