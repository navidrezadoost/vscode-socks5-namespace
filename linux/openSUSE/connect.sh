#!/bin/bash
# VSCode SOCKS5 Namespace - openSUSE
# Optimized for openSUSE Leap and Tumbleweed

# Source the base script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_SCRIPT="$SCRIPT_DIR/../../common/connect-base.sh"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  VSCode SOCKS5 VPN Namespace - openSUSE${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for required dependencies
echo -e "${YELLOW}Checking openSUSE dependencies...${NC}"
MISSING_PKGS=()

# Map commands to openSUSE packages
declare -A PKG_MAP=(
    ["openvpn"]="openvpn"
    ["socat"]="socat"
    ["curl"]="curl"
    ["iptables"]="iptables"
    ["ip"]="iproute2"
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
    echo "  sudo zypper install ${MISSING_PKGS[*]}"
    echo ""
    read -p "Install missing packages now? (y/n) [y]: " INSTALL
    INSTALL=${INSTALL:-y}
    
    if [[ "$INSTALL" =~ ^[Yy]$ ]]; then
        echo "Installing packages..."
        sudo zypper install -y "${MISSING_PKGS[@]}"
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

# openSUSE-specific: Check if SuSEfirewall2 or firewalld is active
if systemctl is-active --quiet SuSEfirewall2; then
    echo -e "${YELLOW}Note: SuSEfirewall2 is active${NC}"
    echo "The script will add iptables rules. You may need to configure SuSEfirewall2."
    echo ""
elif systemctl is-active --quiet firewalld; then
    echo -e "${YELLOW}Note: firewalld is active${NC}"
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
