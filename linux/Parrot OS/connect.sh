#!/bin/bash
# VSCode/JetBrains SOCKS5 Namespace - Parrot OS
# Optimized for Parrot OS (security-focused distribution)

# Source the base script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_SCRIPT="$SCRIPT_DIR/../common/connect-base.sh"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  VSCode/JetBrains SOCKS5 VPN Namespace - Parrot OS${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for required dependencies (most should be pre-installed on Kali)
echo -e "${YELLOW}Checking Kali Linux dependencies...${NC}"
MISSING_PKGS=()

# Map commands to Debian packages (Kali is Debian-based)
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
    echo "  sudo apt update"
    echo "  sudo apt install ${MISSING_PKGS[*]}"
    echo ""
    read -p "Install missing packages now? (y/n) [y]: " INSTALL
    INSTALL=${INSTALL:-y}
    
    if [[ "$INSTALL" =~ ^[Yy]$ ]]; then
        echo "Updating package list..."
        sudo apt update
        echo "Installing packages..."
        sudo apt install -y "${MISSING_PKGS[@]}"
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

# Kali-specific: Warn about multiple VPN connections in pentesting
echo -e "${YELLOW}═══════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  ⚠️  KALI PENTESTING NOTICE  ⚠️${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════${NC}"
echo ""
echo "This script creates an isolated VPN namespace for VSCode."
echo "Your pentesting tools running on the host will use your REAL IP."
echo "Only VSCode traffic through the namespace will use the VPN IP."
echo ""
echo "Use cases:"
echo "  ✓ Development work on VSCode through VPN"
echo "  ✓ Keeping host IP for local network testing"
echo "  ✗ NOT for routing all pentesting traffic through VPN"
echo ""
read -p "Understand and continue? (y/n) [y]: " CONTINUE
CONTINUE=${CONTINUE:-y}

if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
    echo "Setup cancelled."
    exit 0
fi

echo ""

# Run the base connect script
if [ -f "$BASE_SCRIPT" ]; then
    bash "$BASE_SCRIPT"
else
    echo -e "${RED}Error: Base script not found at $BASE_SCRIPT${NC}"
    echo "Please ensure the repository structure is intact."
    exit 1
fi
