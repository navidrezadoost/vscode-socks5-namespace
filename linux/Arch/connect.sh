#!/bin/bash
# VSCode SOCKS5 Namespace - Arch Linux
# Optimized for Arch Linux with pacman package manager

# Source the base script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_SCRIPT="$SCRIPT_DIR/../../common/connect-base.sh"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  VSCode SOCKS5 VPN Namespace - Arch Linux${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo ""

# Check if running on Arch Linux
if [ ! -f /etc/arch-release ]; then
    echo -e "${YELLOW}Warning: This script is optimized for Arch Linux${NC}"
    echo -e "${YELLOW}You appear to be running a different distribution.${NC}"
    read -p "Continue anyway? (y/n) [n]: " CONTINUE
    if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for required dependencies
echo -e "${YELLOW}Checking Arch Linux dependencies...${NC}"
MISSING_PKGS=()

# Map commands to Arch packages
declare -A PKG_MAP=(
    ["openvpn"]="openvpn"
    ["socat"]="socat"
    ["curl"]="curl"
    ["iptables"]="iptables"
    ["ip"]="iproute2"
    ["sockd"]="dante"
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
    echo "  sudo pacman -S ${MISSING_PKGS[*]}"
    echo ""
    read -p "Install missing packages now? (y/n) [y]: " INSTALL
    INSTALL=${INSTALL:-y}
    
    if [[ "$INSTALL" =~ ^[Yy]$ ]]; then
        echo "Installing packages..."
        sudo pacman -S --needed --noconfirm "${MISSING_PKGS[@]}"
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

# Ensure required services are enabled (Arch-specific)
if systemctl list-unit-files | grep -q "iptables.service"; then
    if ! systemctl is-enabled iptables.service >/dev/null 2>&1; then
        echo -e "${YELLOW}Enabling iptables service...${NC}"
        sudo systemctl enable iptables.service
    fi
fi

# Run the base connect script
if [ -f "$BASE_SCRIPT" ]; then
    bash "$BASE_SCRIPT"
else
    echo -e "${RED}Error: Base script not found at $BASE_SCRIPT${NC}"
    echo "Please ensure the repository structure is intact."
    exit 1
fi
