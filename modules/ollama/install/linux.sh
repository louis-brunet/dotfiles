#!/usr/bin/env bash

# 
# # Return 1 if the system is not running Ubuntu 24.04
# check_ubuntu_2404() {
#     # Method 1: Check /etc/os-release (most reliable)
#     if [[ -f /etc/os-release ]]; then
#         source /etc/os-release
#         if [[ "$ID" == "ubuntu" && "$VERSION_ID" == "24.04" ]]; then
#             return 0
#         fi
#     fi
# 
#     # Method 2: Check /etc/lsb-release (fallback)
#     if [[ -f /etc/lsb-release ]]; then
#         source /etc/lsb-release
#         if [[ "$DISTRIB_ID" == "Ubuntu" && "$DISTRIB_RELEASE" == "24.04" ]]; then
#             return 0
#         fi
#     fi
# 
#     # Method 3: Use lsb_release command (if available)
#     if command -v lsb_release >/dev/null 2>&1; then
#         distrib=$(lsb_release -si 2>/dev/null)
#         version=$(lsb_release -sr 2>/dev/null)
#         if [[ "$distrib" == "Ubuntu" && "$version" == "24.04" ]]; then
#             return 0
#         fi
#     fi
# 
#     return 1
# }
# 
# _rp_ok()   { echo "✓ $*"; }
# _rp_warn() { echo "✗ $*"; }
# _rp_info() { echo "! $*"; }
# 
# rocm_preflight() {
#     local failed=0
#     local os_id os_codename pretty arch gpus removals avail_gb
# 
#     # 1. OS and architecture
#     if [[ -r /etc/os-release ]]; then
#         read -r os_id os_codename pretty < <(
#             . /etc/os-release && printf '%s %s %s\n' "$ID" "${VERSION_CODENAME:-}" "$PRETTY_NAME"
#         )
#     fi
#     if [[ "${os_id:-}" == "ubuntu" && "${os_codename:-}" == "noble" ]]; then
#         _rp_ok "Ubuntu 24.04 (noble)"
#     else
#         _rp_warn "Need Ubuntu 24.04 (noble), found: ${pretty:-unknown}"
#         failed=1
#     fi
# 
#     arch=$(dpkg --print-architecture 2>/dev/null)
#     if [[ "$arch" == "amd64" ]]; then
#         _rp_ok "Architecture amd64"
#     else
#         _rp_warn "Architecture is '${arch:-unknown}', need amd64"
#         failed=1
#     fi
# 
#     # 2. Hardware (10de = NVIDIA, 1002 = AMD)
#     if ! command -v lspci >/dev/null 2>&1; then
#         _rp_warn "lspci not found. Install pciutils to check hardware"
#         failed=1
#     else
#         gpus=$(lspci -nn 2>/dev/null | grep -iE 'vga|3d|display' || true)
#         echo "Detected display controllers:"
#         sed 's/^/    /' <<<"$gpus"
# 
#         if grep -q '\[10de:' <<<"$gpus"; then
#             if [[ "${ALLOW_NVIDIA:-0}" == "1" ]]; then
#                 _rp_info "NVIDIA GPU present, continuing because ALLOW_NVIDIA=1"
#             else
#                 _rp_warn "NVIDIA GPU present. ROCm can displace the NVIDIA driver (set ALLOW_NVIDIA=1 to override)"
#                 failed=1
#             fi
#         fi
# 
#         if grep -q '\[1002:' <<<"$gpus"; then
#             _rp_ok "AMD GPU found. Confirm it is on AMD's ROCm support list"
#         else
#             _rp_warn "No AMD GPU found"
#             failed=1
#         fi
#     fi
# 
#     # 3. NVIDIA driver already loaded or installed
#     if lsmod 2>/dev/null | grep -q '^nvidia'; then
#         _rp_warn "nvidia kernel module is loaded"
#         failed=1
#     fi
#     if dpkg -l 'nvidia-*' 2>/dev/null | grep -q '^ii'; then
#         _rp_warn "NVIDIA driver packages are installed"
#         failed=1
#     fi
# 
#     # 4. dpkg database health
#     if [[ -n "$(dpkg --audit 2>/dev/null)" ]]; then
#         _rp_warn "dpkg has broken or half-installed packages. Run 'dpkg --configure -a' and 'apt-get -f install' first"
#         failed=1
#     else
#         _rp_ok "dpkg database is clean"
#     fi
# 
#     # 5. Would installing rocm remove anything? Needs the ROCm repo configured.
#     if ! apt-cache show rocm >/dev/null 2>&1; then
#         _rp_warn "ROCm repo is not configured, so removals can't be checked. Add the repo and run 'apt-get update'"
#         failed=1
#     else
#         removals=$(apt-get -s install rocm 2>/dev/null | awk '/^Remv/{print $2}')
#         if [[ -n "$removals" ]]; then
#             _rp_warn "Installing rocm would REMOVE these packages:"
#             sed 's/^/    /' <<<"$removals"
#             failed=1
#         else
#             _rp_ok "Installing rocm removes nothing"
#         fi
#     fi
# 
#     # 6. Disk space (about 30 GB needed)
#     avail_gb=$(df --output=avail -BG /usr 2>/dev/null | tail -1 | tr -dc '0-9')
#     if [[ -n "$avail_gb" ]] && (( avail_gb >= 30 )); then
#         _rp_ok "${avail_gb} GB free under /usr"
#     else
#         _rp_warn "Only ${avail_gb:-unknown} GB free under /usr (need about 30 GB)"
#         failed=1
#     fi
# 
#     # 7. Network to AMD's repo
#     if curl -sfI --max-time 10 https://repo.radeon.com/ >/dev/null 2>&1; then
#         _rp_ok "repo.radeon.com is reachable"
#     else
#         _rp_warn "Cannot reach repo.radeon.com"
#         failed=1
#     fi
# 
#     # 8. Secure Boot (unsigned DKMS modules won't load when it's on)
#     if command -v mokutil >/dev/null 2>&1 && mokutil --sb-state 2>/dev/null | grep -qi 'enabled'; then
#         _rp_info "Secure Boot is enabled. ROCm kernel modules must be signed and enrolled to load"
#     fi
# 
#     echo
#     if (( failed )); then
#         echo "Preflight FAILED. Nothing was installed."
#         return 1
#     fi
#     echo "Preflight passed. Safe to run the install steps."
#     return 0
# }
# 
# # Main execution
# if ! rocm_preflight; then
#    echo "✗ This system is NOT compatible with the AMD GPU (ROCm) installation script. Exiting."
#    exit 0
# fi
# 
# 
# if check_ubuntu_2404; then
#     echo "✓ This system is running Ubuntu 24.04. Installing ROCm"
#     # --- Configure rocm for access to AMD GPU
# 
#     wget https://repo.radeon.com/amdgpu-install/6.4.1/ubuntu/noble/amdgpu-install_6.4.60401-1_all.deb
#     sudo apt install ./amdgpu-install_6.4.60401-1_all.deb
#     sudo apt update
#     sudo apt install python3-setuptools python3-wheel
# 
#     # Add the current user to the render and video groups. These can be added to docker configs as well.
#     sudo usermod -a -G render,video "$LOGNAME"
# 
#     # Install ROCm
#     sudo apt install rocm -y
#     exit 0
# else
#     echo "✗ This system is NOT running Ubuntu 24.04"
# 
#     # Show current distribution info if available
#     if [[ -f /etc/os-release ]]; then
#         source /etc/os-release
#         echo "Current distribution: $PRETTY_NAME"
#     elif command -v lsb_release >/dev/null 2>&1; then
#         echo "Current distribution: $(lsb_release -ds 2>/dev/null)"
#     fi
# 
#     echo "ROCm installation is not supported by this installation script"
# 
#     exit 1
# fi
# 
