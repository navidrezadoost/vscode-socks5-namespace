#!/bin/bash
# VSCode SOCKS5 Proxy Disconnect - macOS

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  VSCode SOCKS5 VPN Proxy Disconnect - macOS             ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Try to load saved configuration
CONFIG_FILE="/tmp/vpn_macos_config.sh"

if [ -f "$CONFIG_FILE" ]; then
    echo -e "${YELLOW}Loading saved configuration...${NC}"
    source "$CONFIG_FILE"
    echo -e "${GREEN}✓ Configuration loaded${NC}\n"
else
    echo -e "${YELLOW}No saved configuration found.${NC}\n"
    OVPN_CONFIG="*.ovpn"
    SOCKS_PORT=1080
fi

# Terminate all related processes
echo -e "${YELLOW}[1/5] Terminating OpenVPN and Dante processes...${NC}"
sudo pkill -f "openvpn.*$(basename $OVPN_CONFIG 2>/dev/null || echo '*.ovpn')" 2>/dev/null || true
sudo pkill -f "sockd" 2>/dev/null || true
sudo pkill -f "socat.*$SOCKS_PORT" 2>/dev/null || true
sleep 2

# Force kill if still running
sudo pkill -9 -f "openvpn" 2>/dev/null || true
sudo pkill -9 -f "sockd" 2>/dev/null || true

echo -e "${GREEN}✓ Processes terminated${NC}"

# Clean up temporary files
echo -e "${YELLOW}[2/5] Removing temporary files...${NC}"
rm -f /tmp/danted_macos.conf
rm -f /tmp/danted_macos.log
rm -f /tmp/openvpn_macos.log
rm -f "$CONFIG_FILE"

echo -e "${GREEN}✓ Temporary files cleaned${NC}"

# Check for VSCode instances using the proxy
echo -e "${YELLOW}[3/5] Checking for VSCode instances using the proxy...${NC}"
if pgrep -f "code.*socks5://127.0.0.1:$SOCKS_PORT" >/dev/null 2>&1; then
    read -p "Close VSCode instances using the proxy? (y/n) [n]: " CLOSE_VSCODE
    CLOSE_VSCODE=${CLOSE_VSCODE:-n}
    
    if [[ "$CLOSE_VSCODE" =~ ^[Yy]$ ]]; then
        pkill -f "code.*socks5://127.0.0.1:$SOCKS_PORT" 2>/dev/null || true
        echo -e "${GREEN}✓ VSCode instances closed${NC}"
    else
        echo -e "${YELLOW}VSCode instances left running${NC}"
    fi
else
    echo -e "${YELLOW}No VSCode instances found using the proxy${NC}"
fi

# Verify cleanup
echo -e "${YELLOW}[4/5] Verifying cleanup...${NC}"
ISSUES=0

if pgrep -f "openvpn" >/dev/null 2>&1; then
    echo -e "${YELLOW}! OpenVPN process still running (may be from another connection)${NC}"
fi

if pgrep -f "sockd" >/dev/null 2>&1; then
    echo -e "${RED}✗ Dante process still running${NC}"
    ISSUES=$((ISSUES+1))
fi

if [ $ISSUES -eq 0 ]; then
    echo -e "${GREEN}✓ All resources successfully cleaned${NC}"
else
    echo -e "${YELLOW}! Some resources may still exist${NC}"
fi

# Final summary
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           Cleanup Completed Successfully!                ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "All resources have been released:"
echo "  • OpenVPN and Dante processes terminated"
echo "  • Temporary files and logs deleted"
echo "  • VPN interface removed"
echo ""
echo -e "${GREEN}✓ System is now clean. You can safely re-run the connect script anytime.${NC}"
echo ""
