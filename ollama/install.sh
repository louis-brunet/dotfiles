#!/usr/bin/env bash

set -e

# Return 1 if the system is not running Ubuntu 24.04
check_ubuntu_2404() {
    # Method 1: Check /etc/os-release (most reliable)
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        if [[ "$ID" == "ubuntu" && "$VERSION_ID" == "24.04" ]]; then
            return 0
        fi
    fi

    # Method 2: Check /etc/lsb-release (fallback)
    if [[ -f /etc/lsb-release ]]; then
        source /etc/lsb-release
        if [[ "$DISTRIB_ID" == "Ubuntu" && "$DISTRIB_RELEASE" == "24.04" ]]; then
            return 0
        fi
    fi

    # Method 3: Use lsb_release command (if available)
    if command -v lsb_release >/dev/null 2>&1; then
        distrib=$(lsb_release -si 2>/dev/null)
        version=$(lsb_release -sr 2>/dev/null)
        if [[ "$distrib" == "Ubuntu" && "$version" == "24.04" ]]; then
            return 0
        fi
    fi

    return 1
}

# Main execution
if check_ubuntu_2404; then
    echo "✓ This system is running Ubuntu 24.04. Installing ROCm"
    # --- Configure rocm for access to AMD GPU

    wget https://repo.radeon.com/amdgpu-install/6.4.1/ubuntu/noble/amdgpu-install_6.4.60401-1_all.deb
    sudo apt install ./amdgpu-install_6.4.60401-1_all.deb
    sudo apt update
    sudo apt install python3-setuptools python3-wheel

    # Add the current user to the render and video groups. These can be added to docker configs as well.
    sudo usermod -a -G render,video "$LOGNAME"

    # Install ROCm
    sudo apt install rocm -y
    exit 0
else
    echo "✗ This system is NOT running Ubuntu 24.04"

    # Show current distribution info if available
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        echo "Current distribution: $PRETTY_NAME"
    elif command -v lsb_release >/dev/null 2>&1; then
        echo "Current distribution: $(lsb_release -ds 2>/dev/null)"
    fi

    echo "ROCm installation is not supported by this installation script"

    exit 1
fi

