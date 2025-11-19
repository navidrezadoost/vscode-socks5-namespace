#!/bin/bash
# cleanup-vpnspace.sh - Clean up VPN namespace and all resources
# Usage: sudo ./cleanup-vpnspace.sh

set +e  # Don't exit on errors, we want to clean up as much as possible

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration (must match start-vpnspace.sh)
NAMESPACE="vpnspace"
VETH_HOST="veth_host"
NS_IP="10.200.200.2"
DANTE_CONFIG="/tmp/danted-vpnspace.conf"
OVPN_PID_FILE="/tmp/vpnspace-openvpn.pid"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run as root (use sudo)${NC}"
    exit 1
fi

echo -e "${GREEN}=== Cleaning Up VPN Namespace ===${NC}"

# Kill OpenVPN if running
if [ -f "$OVPN_PID_FILE" ]; then
    OVPN_PID=$(cat "$OVPN_PID_FILE")
    if kill -0 "$OVPN_PID" 2>/dev/null; then
        echo -e "${YELLOW}Stopping OpenVPN (PID: $OVPN_PID)...${NC}"
        kill "$OVPN_PID" 2>/dev/null || true
        sleep 2
        kill -9 "$OVPN_PID" 2>/dev/null || true
    fi
    rm -f "$OVPN_PID_FILE"
fi

# Kill any remaining OpenVPN processes in namespace
echo -e "${YELLOW}Checking for remaining OpenVPN processes...${NC}"
ip netns pids $NAMESPACE 2>/dev/null | while read -r pid; do
    if [ -n "$pid" ]; then
        PNAME=$(ps -p "$pid" -o comm= 2>/dev/null || echo "unknown")
        echo -e "${YELLOW}Killing process $pid ($PNAME) in namespace...${NC}"
        kill -9 "$pid" 2>/dev/null || true
    fi
done

# Kill Dante SOCKS server
echo -e "${YELLOW}Stopping SOCKS5 proxy...${NC}"
pkill -f "danted.*$DANTE_CONFIG" 2>/dev/null || true
sleep 1

# Remove veth interface (this also removes the peer)
if ip link show $VETH_HOST &> /dev/null; then
    echo -e "${YELLOW}Removing virtual ethernet interface...${NC}"
    ip link delete $VETH_HOST 2>/dev/null || true
fi

# Delete network namespace
if ip netns list | grep -q "^${NAMESPACE}"; then
    echo -e "${YELLOW}Deleting network namespace '$NAMESPACE'...${NC}"
    ip netns delete $NAMESPACE 2>/dev/null || true
fi

# Clean up iptables rules
echo -e "${YELLOW}Cleaning up iptables rules...${NC}"
iptables -t nat -D POSTROUTING -s ${NS_IP}/32 -j MASQUERADE 2>/dev/null || true
iptables -D FORWARD -i $VETH_HOST -j ACCEPT 2>/dev/null || true
iptables -D FORWARD -o $VETH_HOST -j ACCEPT 2>/dev/null || true

# Remove Dante config
if [ -f "$DANTE_CONFIG" ]; then
    echo -e "${YELLOW}Removing SOCKS5 config file...${NC}"
    rm -f $DANTE_CONFIG
fi

echo ""
echo -e "${GREEN}✓ Cleanup completed${NC}"
echo ""
