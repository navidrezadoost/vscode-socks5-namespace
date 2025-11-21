#!/bin/bash
# VSCode/JetBrains SOCKS5 Namespace - Manjaro Linux
# Optimized for Manjaro (user-friendly Arch-based distribution)

# Source the base script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_SCRIPT="$SCRIPT_DIR/../common/connect-base.sh"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  VSCode/JetBrains SOCKS5 VPN Namespace - Manjaro Linux${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for required dependencies
echo -e "${YELLOW}Checking Manjaro dependencies...${NC}"
MISSING_PKGS=()

# Map commands to Manjaro packages (same as Arch, but we check both official and AUR)
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
            echo -e "${RED}Failed to install some packages.${NC}"
            echo -e "${YELLOW}Trying with yay (AUR helper) if available...${NC}"
            
            if command_exists yay; then
                yay -S --needed --noconfirm "${MISSING_PKGS[@]}"
                if [ $? -eq 0 ]; then
                    echo -e "${GREEN}✓ Packages installed successfully via AUR${NC}"
                else
                    echo -e "${RED}Failed to install packages. Please install manually.${NC}"
                    exit 1
                fi
            else
                echo -e "${RED}AUR helper (yay) not found. Please install manually:${NC}"
                echo "  sudo pacman -S ${MISSING_PKGS[*]}"
                exit 1
            fi
        fi
    else
        echo "Please install the required packages and run this script again."
        exit 1
    fi
fi

echo -e "${GREEN}✓ All dependencies satisfied${NC}\n"

# Manjaro-specific: Check if using Pamac
if command_exists pamac; then
    echo -e "${YELLOW}Tip: You can also use Pamac GUI to manage packages${NC}"
fi

# Manjaro-specific: Check firewall (ufw or firewalld)
if systemctl is-active --quiet ufw; then
    echo -e "${YELLOW}Note: UFW firewall is active${NC}"
    echo "You may need to allow traffic from 10.200.200.0/24"
    echo "Run after setup: sudo ufw allow from 10.200.200.0/24"
    echo ""
elif systemctl is-active --quiet firewalld; then
    echo -e "${YELLOW}Note: firewalld is active${NC}"
    echo "You may need to configure firewalld zones for the namespace."
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
