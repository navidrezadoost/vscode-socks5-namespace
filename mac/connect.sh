#!/bin/bash
# VSCode SOCKS5 Proxy - macOS
# Alternative approach for macOS (network namespaces not available)
# Uses local SOCKS proxy with routing table manipulation

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  VSCode SOCKS5 VPN Proxy - macOS                        ║${NC}"
echo -e "${GREEN}║  OpenVPN + SOCKS5 proxy for VSCode                      ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# macOS doesn't support network namespaces like Linux
echo -e "${YELLOW}═══════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  ⚠️  macOS LIMITATION NOTICE  ⚠️${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════${NC}"
echo ""
echo "macOS does not support Linux network namespaces."
echo "This script provides an alternative approach:"
echo ""
echo "  • Runs OpenVPN in background"
echo "  • Creates SOCKS5 proxy on the VPN connection"
echo "  • VSCode uses the SOCKS5 proxy"
echo ""
echo -e "${YELLOW}Note: Unlike Linux version, ALL traffic through the VPN${NC}"
echo -e "${YELLOW}interface will be affected, not just VSCode.${NC}"
echo ""
echo "For true isolation, consider:"
echo "  • Using a VM with Linux"
echo "  • Using Docker containers"
echo "  • Using macOS's built-in VPN with split tunneling"
echo ""
read -p "Continue with limited macOS setup? (y/n) [y]: " CONTINUE
CONTINUE=${CONTINUE:-y}

if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
    echo "Setup cancelled."
    exit 0
fi

echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for Homebrew
if ! command_exists brew; then
    echo -e "${RED}Error: Homebrew not found!${NC}"
    echo "Install Homebrew first: https://brew.sh"
    echo ""
    echo "/bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    exit 1
fi

# Check for required dependencies
echo -e "${YELLOW}Checking macOS dependencies...${NC}"
MISSING_PKGS=()

# Map commands to Homebrew packages
declare -A PKG_MAP=(
    ["openvpn"]="openvpn"
    ["socat"]="socat"
    ["curl"]="curl"
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
    echo "  brew install ${MISSING_PKGS[*]}"
    echo ""
    read -p "Install missing packages now? (y/n) [y]: " INSTALL
    INSTALL=${INSTALL:-y}
    
    if [[ "$INSTALL" =~ ^[Yy]$ ]]; then
        echo "Installing packages..."
        brew install "${MISSING_PKGS[@]}"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Packages installed successfully${NC}"
        else
            echo -e "${RED}Failed to install packages.${NC}"
            exit 1
        fi
    else
        echo "Please install the required packages and run this script again."
        exit 1
    fi
fi

echo -e "${GREEN}✓ All dependencies satisfied${NC}\n"

# Collect configuration from user
echo -e "${YELLOW}Configuration Setup${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# OpenVPN config
while true; do
    read -p "Enter full path to your OpenVPN config file: " OVPN_CONFIG
    if [ -f "$OVPN_CONFIG" ]; then
        break
    else
        echo -e "${RED}File not found. Please enter a valid path.${NC}"
    fi
done

# SOCKS port
read -p "Enter SOCKS5 port [1080]: " SOCKS_PORT
SOCKS_PORT=${SOCKS_PORT:-1080}

# DNS server
read -p "Enter DNS server [8.8.8.8]: " DNS_SERVER
DNS_SERVER=${DNS_SERVER:-8.8.8.8}

# Launch VSCode option
read -p "Launch VSCode with proxy after setup? (y/n) [y]: " LAUNCH_VSCODE
LAUNCH_VSCODE=${LAUNCH_VSCODE:-y}

echo ""
echo -e "${GREEN}Configuration Summary:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "OpenVPN Config:         $OVPN_CONFIG"
echo "SOCKS Port:             $SOCKS_PORT"
echo "DNS Server:             $DNS_SERVER"
echo "Launch VSCode:          $LAUNCH_VSCODE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

read -p "Proceed with setup? (y/n) [y]: " CONFIRM
CONFIRM=${CONFIRM:-y}

if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Setup cancelled."
    exit 0
fi

echo ""
echo -e "${GREEN}Starting setup...${NC}"

# Clean up previous instances
echo -e "${YELLOW}[1/7] Cleaning up previous instances...${NC}"
sudo pkill -f "openvpn.*$(basename $OVPN_CONFIG)" 2>/dev/null || true
sudo pkill -f "sockd" 2>/dev/null || true
sudo pkill -f "socat.*$SOCKS_PORT" 2>/dev/null || true
sleep 1

# Start OpenVPN
echo -e "${YELLOW}[2/7] Starting OpenVPN...${NC}"
sudo openvpn --config "$OVPN_CONFIG" --daemon --log /tmp/openvpn_macos.log

# Wait for tun interface
echo -e "${YELLOW}[3/7] Waiting for VPN connection...${NC}"
VPN_CONNECTED=false
for i in {1..30}; do
    if ifconfig | grep -q "utun"; then
        # Find the utun interface created by OpenVPN
        VPN_IF=$(ifconfig | grep "^utun" | head -1 | cut -d: -f1)
        VPN_IP=$(ifconfig $VPN_IF | grep "inet " | awk '{print $2}')
        echo -e "${GREEN}✓ VPN connected! Interface: $VPN_IF, IP: $VPN_IP${NC}"
        VPN_CONNECTED=true
        break
    fi
    echo -n "."
    sleep 1
done
echo ""

if [ "$VPN_CONNECTED" = false ]; then
    echo -e "${RED}Error: VPN connection failed!${NC}"
    echo "Check OpenVPN logs: /tmp/openvpn_macos.log"
    exit 1
fi

# Generate Dante SOCKS5 server configuration
echo -e "${YELLOW}[4/7] Generating SOCKS5 server configuration...${NC}"
DANTE_CONF="/tmp/danted_macos.conf"
cat > $DANTE_CONF <<EOF
logoutput: /tmp/danted_macos.log
internal: 127.0.0.1 port = $SOCKS_PORT
external: $VPN_IF
socksmethod: none
clientmethod: none
user.privileged: root
user.unprivileged: nobody

client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: error
}

socks pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    command: bind connect udpassociate
    log: error
}
EOF

# Start Dante SOCKS5 server
echo -e "${YELLOW}[5/7] Starting SOCKS5 proxy server...${NC}"
sudo sockd -f $DANTE_CONF -D &
sleep 3

# Test SOCKS5 proxy
echo -e "${YELLOW}[6/7] Testing proxy connectivity...${NC}"
PROXY_IP=$(curl -s --connect-timeout 10 --socks5-hostname 127.0.0.1:$SOCKS_PORT https://api.ipify.org 2>/dev/null)
if [[ -n "$PROXY_IP" ]]; then
    echo -e "${GREEN}✓ Proxy working! Public IP: $PROXY_IP${NC}"
else
    echo -e "${RED}Error: Proxy test failed${NC}"
    echo "Check Dante logs: /tmp/danted_macos.log"
    exit 1
fi

# Save configuration
CONFIG_FILE="/tmp/vpn_macos_config.sh"
cat > $CONFIG_FILE <<EOF
# Auto-generated configuration for VPN proxy
SOCKS_PORT=$SOCKS_PORT
OVPN_CONFIG="$OVPN_CONFIG"
VPN_IF="$VPN_IF"
EOF

# Final summary
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              Setup Completed Successfully!               ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Proxy Configuration:${NC}"
echo "  SOCKS5 Address:  socks5://127.0.0.1:$SOCKS_PORT"
echo "  VPN Interface:   $VPN_IF"
echo "  VPN Public IP:   $PROXY_IP"
echo ""
echo -e "${YELLOW}To use with VSCode:${NC}"
echo "  code --proxy-server=\"socks5://127.0.0.1:$SOCKS_PORT\""
echo ""
echo -e "${YELLOW}To disconnect:${NC}"
echo "  Run the disconnect script: ./disconnect.sh"
echo ""

# Launch VSCode
if [[ "$LAUNCH_VSCODE" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}[7/7] Launching VSCode with SOCKS5 proxy...${NC}"
    if command_exists code; then
        code --proxy-server="socks5://127.0.0.1:$SOCKS_PORT" &
        echo -e "${GREEN}✓ VSCode launched${NC}"
    else
        echo -e "${YELLOW}Warning: VSCode (code command) not found in PATH${NC}"
        echo "You can manually launch it with: code --proxy-server=\"socks5://127.0.0.1:$SOCKS_PORT\""
    fi
fi

echo ""
echo -e "${GREEN}✓ All done!${NC}"
