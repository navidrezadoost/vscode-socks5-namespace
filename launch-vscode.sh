#!/bin/bash
# launch-vscode.sh - Launch VSCode with SOCKS5 proxy configuration
# Usage: ./launch-vscode.sh

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SOCKS_PORT="1080"
SOCKS_PROXY="socks5://localhost:$SOCKS_PORT"

# Check if SOCKS proxy is running
if ! nc -z localhost $SOCKS_PORT 2>/dev/null; then
    echo -e "${RED}Error: SOCKS5 proxy is not running on port $SOCKS_PORT${NC}"
    echo -e "${YELLOW}Please start the VPN namespace first:${NC}"
    echo -e "  sudo ./start-vpnspace.sh <path-to-ovpn-config>"
    exit 1
fi

echo -e "${GREEN}=== Launching VSCode with VPN Proxy ===${NC}"
echo -e "${YELLOW}SOCKS5 proxy: $SOCKS_PROXY${NC}"
echo ""

# Check if code command exists
if ! command -v code &> /dev/null; then
    echo -e "${RED}Error: 'code' command not found${NC}"
    echo -e "${YELLOW}Please install VSCode or add it to your PATH${NC}"
    exit 1
fi

# Launch VSCode with proxy settings
# The proxy settings are passed via command line arguments
echo -e "${YELLOW}Starting VSCode...${NC}"

# Set environment variables for the proxy
export http_proxy="$SOCKS_PROXY"
export https_proxy="$SOCKS_PROXY"
export HTTP_PROXY="$SOCKS_PROXY"
export HTTPS_PROXY="$SOCKS_PROXY"

# Launch VSCode with proxy arguments
code --proxy-server="$SOCKS_PROXY" "$@" &

echo ""
echo -e "${GREEN}✓ VSCode launched with proxy configuration${NC}"
echo ""
echo -e "All VSCode network traffic will go through the isolated VPN connection."
echo ""
echo -e "To verify the VPN is working, you can:"
echo -e "  1. Open VSCode's integrated terminal"
echo -e "  2. Check your IP: ${YELLOW}curl --socks5 localhost:$SOCKS_PORT https://ifconfig.me${NC}"
echo ""
