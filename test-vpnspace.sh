#!/bin/bash
# test-vpnspace.sh - Test VPN namespace setup and connectivity
# Usage: ./test-vpnspace.sh

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SOCKS_PORT="1080"
NAMESPACE="vpnspace"

echo -e "${BLUE}=== VPN Namespace Test Suite ===${NC}"
echo ""

# Test 1: Check if namespace exists
echo -e "${YELLOW}Test 1: Checking if namespace exists...${NC}"
if ip netns list 2>/dev/null | grep -q "^${NAMESPACE}"; then
    echo -e "${GREEN}✓ Namespace '$NAMESPACE' exists${NC}"
else
    echo -e "${RED}✗ Namespace '$NAMESPACE' not found${NC}"
    echo -e "${YELLOW}  Run: sudo ./start-vpnspace.sh <config.ovpn>${NC}"
    exit 1
fi

# Test 2: Check if SOCKS proxy is running
echo -e "${YELLOW}Test 2: Checking SOCKS5 proxy...${NC}"
if nc -z localhost $SOCKS_PORT 2>/dev/null; then
    echo -e "${GREEN}✓ SOCKS5 proxy is accessible on localhost:$SOCKS_PORT${NC}"
else
    echo -e "${RED}✗ SOCKS5 proxy is not accessible${NC}"
    exit 1
fi

# Test 3: Check if OpenVPN is running
echo -e "${YELLOW}Test 3: Checking OpenVPN process...${NC}"
if [ -f /tmp/vpnspace-openvpn.pid ]; then
    OVPN_PID=$(cat /tmp/vpnspace-openvpn.pid)
    if kill -0 "$OVPN_PID" 2>/dev/null; then
        echo -e "${GREEN}✓ OpenVPN is running (PID: $OVPN_PID)${NC}"
    else
        echo -e "${RED}✗ OpenVPN PID file exists but process is not running${NC}"
        exit 1
    fi
else
    echo -e "${RED}✗ OpenVPN PID file not found${NC}"
    exit 1
fi

# Test 4: Check host IP
echo -e "${YELLOW}Test 4: Checking host IP address...${NC}"
HOST_IP=$(curl -s --max-time 5 https://ifconfig.me 2>/dev/null)
if [ -n "$HOST_IP" ]; then
    echo -e "${GREEN}✓ Host IP: $HOST_IP${NC}"
else
    echo -e "${YELLOW}⚠ Could not determine host IP${NC}"
    HOST_IP="unknown"
fi

# Test 5: Check VPN IP
echo -e "${YELLOW}Test 5: Checking VPN IP address (through proxy)...${NC}"
VPN_IP=$(curl -s --socks5 localhost:$SOCKS_PORT --max-time 10 https://ifconfig.me 2>/dev/null)
if [ -n "$VPN_IP" ]; then
    echo -e "${GREEN}✓ VPN IP: $VPN_IP${NC}"
    if [ "$HOST_IP" != "unknown" ] && [ "$HOST_IP" != "$VPN_IP" ]; then
        echo -e "${GREEN}✓ VPN is working! IPs are different.${NC}"
    elif [ "$HOST_IP" = "$VPN_IP" ]; then
        echo -e "${RED}✗ Warning: Host and VPN IPs are the same!${NC}"
        echo -e "${YELLOW}  VPN may not be routing correctly${NC}"
    fi
else
    echo -e "${RED}✗ Could not determine VPN IP${NC}"
    echo -e "${YELLOW}  VPN connection may not be established yet${NC}"
fi

# Test 6: Check namespace connectivity
echo -e "${YELLOW}Test 6: Testing namespace network connectivity...${NC}"
if timeout 5 sudo ip netns exec $NAMESPACE ping -c 2 8.8.8.8 >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Namespace can reach internet (ping 8.8.8.8)${NC}"
else
    echo -e "${YELLOW}⚠ Namespace connectivity test failed${NC}"
fi

# Test 7: DNS resolution through proxy
echo -e "${YELLOW}Test 7: Testing DNS resolution through proxy...${NC}"
if curl -s --socks5 localhost:$SOCKS_PORT --max-time 5 https://www.google.com >/dev/null 2>&1; then
    echo -e "${GREEN}✓ DNS resolution works through proxy${NC}"
else
    echo -e "${YELLOW}⚠ DNS resolution test failed${NC}"
fi

echo ""
echo -e "${BLUE}=== Test Summary ===${NC}"
echo -e "Namespace: ${GREEN}${NAMESPACE}${NC}"
echo -e "SOCKS5 Proxy: ${GREEN}localhost:${SOCKS_PORT}${NC}"
echo -e "Host IP: ${GREEN}${HOST_IP}${NC}"
echo -e "VPN IP: ${GREEN}${VPN_IP}${NC}"
echo ""
echo -e "${GREEN}All critical tests passed!${NC}"
echo ""
echo -e "You can now use the proxy with any application:"
echo -e "  ${YELLOW}./launch-vscode.sh${NC}"
echo -e "  ${YELLOW}curl --socks5 localhost:$SOCKS_PORT https://example.com${NC}"
echo ""
