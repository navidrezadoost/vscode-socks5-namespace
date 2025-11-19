#!/bin/bash
# VSCode SOCKS5 Namespace - Fedora/RHEL
# Optimized for Fedora and RHEL-based distributions

# Source the base script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_SCRIPT="$SCRIPT_DIR/../../common/connect-base.sh"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  VSCode SOCKS5 VPN Namespace - Fedora/RHEL${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Detect package manager
if command_exists dnf; then
    PKG_MGR="dnf"
elif command_exists yum; then
    PKG_MGR="yum"
else
    echo -e "${RED}Error: Neither dnf nor yum found!${NC}"
    exit 1
fi

# Check for required dependencies
echo -e "${YELLOW}Checking Fedora/RHEL dependencies...${NC}"
MISSING_PKGS=()

# Map commands to Fedora/RHEL packages
declare -A PKG_MAP=(
    ["openvpn"]="openvpn"
    ["socat"]="socat"
    ["curl"]="curl"
    ["iptables"]="iptables"
    ["ip"]="iproute"
    ["sockd"]="dante-server"
)

for cmd in "${!PKG_MAP[@]}"; do
    if ! command_exists "$cmd"; then
        MISSING_PKGS+=("${PKG_MAP[$cmd]}")
    fi
done

if [ ${#MISSING_PKGS[@]} -ne 0 ]; then
    echo -e "${RED}Missing required packages: ${MISSING_PKGS[*]}${NC}"
    echo ""
    echo -e "${YELLOW}Install them with:${NC}"
    echo "  sudo $PKG_MGR install ${MISSING_PKGS[*]}"
    echo ""
    read -p "Install missing packages now? (y/n) [y]: " INSTALL
    INSTALL=${INSTALL:-y}
    
    if [[ "$INSTALL" =~ ^[Yy]$ ]]; then
        echo "Installing packages..."
        sudo $PKG_MGR install -y "${MISSING_PKGS[@]}"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Packages installed successfully${NC}"
        else
            echo -e "${RED}Failed to install packages. Please install manually.${NC}"
            exit 1
        fi
    else
        echo "Please install the required packages and run this script again."
        exit 1
    fi
fi

echo -e "${GREEN}✓ All dependencies satisfied${NC}\n"

# Fedora/RHEL-specific: Check SELinux status
if command_exists getenforce; then
    SELINUX_STATUS=$(getenforce)
    if [ "$SELINUX_STATUS" = "Enforcing" ]; then
        echo -e "${YELLOW}Warning: SELinux is in Enforcing mode${NC}"
        echo -e "${YELLOW}If you encounter permission issues, you may need to:${NC}"
        echo "  1. Set SELinux to permissive mode for testing: sudo setenforce 0"
        echo "  2. Or create proper SELinux policies for the namespace"
        echo ""
        read -p "Continue anyway? (y/n) [y]: " CONTINUE
        CONTINUE=${CONTINUE:-y}
        if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
            exit 0
        fi
    fi
fi

# Fedora-specific: Check if firewalld is active
if systemctl is-active --quiet firewalld; then
    echo -e "${YELLOW}Note: firewalld is active${NC}"
    echo -e "${YELLOW}The script will add iptables rules that may conflict with firewalld zones.${NC}"
    echo "You may need to configure firewalld to allow traffic from 10.200.200.0/24"
    echo ""
fi

# Run the base connect script
if [ -f "$BASE_SCRIPT" ]; then
    bash "$BASE_SCRIPT"
else
    echo -e "${RED}Error: Base script not found at $BASE_SCRIPT${NC}"
    echo "Please ensure the repository structure is intact."
    exit 1
fi
