#!/bin/bash

# Check command status function
check_command_status() {
    if [ $? -ne 0 ]; then
        echo "Error encountered at: $1 -- Exiting"
        exit 1
    fi
}

# Variables declaration
REQUIRED_PACKAGES="git libpulse-dev autoconf m4 intltool build-essential dpkg-dev libtool libsndfile1-dev libspeexdsp-dev libudev-dev"
PULSEAUDIO_GIT_URL="https://github.com/neutrinolabs/pulseaudio-module-xrdp.git"
ORIGINAL_DIR="/usr/local/bin/"

# Function to execute commands in a terminal
run_in_terminal() {
    gnome-terminal -- $1
    sleep 5 # Adjust sleep time if needed
}

# Re-execute initial setup script
sudo ./install.sh
check_command_status "Re-executing setup script after reboot"

# Check for already installed packages
for package in $REQUIRED_PACKAGES; do
    dpkg -s $package &> /dev/null 
    if [ $? -ne 0 ]; then
        TO_INSTALL+=" $package"
    fi
done

# Install required packages
if [ -n "$TO_INSTALL" ]; then
    run_in_terminal "sudo apt-get install $TO_INSTALL -y"
    check_command_status "Installing required packages: $TO_INSTALL"
fi

# Install pulseaudio
sudo cp /etc/apt/sources.list /etc/apt/sources.list~
sudo sed -Ei 's/^# deb-src /deb-src /' /etc/apt/sources.list
sudo apt-get update
sudo apt build-dep pulseaudio -y
check_command_status "Installing Pulseaudio"

# Clone and install pulseaudio-module-xrdp
run_in_terminal "git clone $PULSEAUDIO_GIT_URL"
cd pulseaudio-module-xrdp
run_in_terminal "./scripts/install_pulseaudio_sources_apt_wrapper.sh"
run_in_terminal "./bootstrap"
run_in_terminal "./configure PULSE_DIR=~/pulseaudio.src"
run_in_terminal "sudo make install"
check_command_status "Installing pulseaudio-module-xrdp"

# Navigate to original directory
cd $ORIGINAL_DIR

# Clean up
run_in_terminal "sudo apt-get update && sudo apt-get upgrade -y"
run_in_terminal "sudo apt-get autoclean && sudo apt-get autoremove"
run_in_terminal "sudo shutdown -h now"
