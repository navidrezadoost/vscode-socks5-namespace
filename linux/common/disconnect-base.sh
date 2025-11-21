#!/bin/bash
# VSCode/JetBrains SOCKS5 Namespace - Base Disconnect Script
# Clean and complete teardown of the isolated OpenVPN + SOCKS5 setup

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  VSCode/JetBrains SOCKS5 VPN Namespace Disconnect      ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Try to load saved configuration
DEFAULT_NS="vpnspace"
CONFIG_FILE="/tmp/vpnns_${DEFAULT_NS}_config.sh"

if [ -f "$CONFIG_FILE" ]; then
    echo -e "${YELLOW}Loading saved configuration...${NC}"
    source "$CONFIG_FILE"
    echo -e "${GREEN}✓ Configuration loaded${NC}\n"
else
    echo -e "${YELLOW}No saved configuration found. Please provide details:${NC}\n"
    
    read -p "Enter namespace name [vpnspace]: " NS
    NS=${NS:-vpnspace}
    
    read -p "Enter local proxy port [1081]: " LOCAL_PROXY_PORT
    LOCAL_PROXY_PORT=${LOCAL_PROXY_PORT:-1081}
    
    # Auto-detect network interface
    DEFAULT_IF=$(ip route | grep default | awk '{print $5}' | head -1)
    read -p "Enter your main network interface [$DEFAULT_IF]: " EXT_IF
    EXT_IF=${EXT_IF:-$DEFAULT_IF}
    
    # Auto-detect host IP
    DEFAULT_IP=$(ip addr show "$EXT_IF" | grep "inet " | awk '{print $2}' | cut -d/ -f1 | head -1)
    read -p "Enter your host IP address [$DEFAULT_IP]: " HOST_IP
    HOST_IP=${HOST_IP:-$DEFAULT_IP}
    
    OVPN_CONFIG="*.ovpn"
fi

echo -e "${YELLOW}Disconnecting namespace: $NS${NC}"
echo ""

# 1. Terminate all related processes (graceful first)
echo -e "${YELLOW}[1/9] Terminating OpenVPN, Dante, and socat processes...${NC}"
sudo pkill -f "openvpn.*$(basename $OVPN_CONFIG 2>/dev/null || echo '*.ovpn')" 2>/dev/null || true
sudo pkill -f "sockd" 2>/dev/null || true
sudo pkill -f "danted" 2>/dev/null || true
sudo pkill -f "socat.*$LOCAL_PROXY_PORT" 2>/dev/null || true
sleep 2

# Force kill any remaining stubborn processes
sudo pkill -9 -f "openvpn" 2>/dev/null || true
sudo pkill -9 -f "sockd" 2>/dev/null || true
sudo pkill -9 -f "danted" 2>/dev/null || true
sudo pkill -9 -f "socat.*$LOCAL_PROXY_PORT" 2>/dev/null || true

echo -e "${GREEN}✓ Processes terminated${NC}"

# 2. Delete the network namespace (removes tun0, veth1, routes, etc.)
echo -e "${YELLOW}[2/9] Deleting network namespace '$NS'...${NC}"
if sudo ip netns delete $NS 2>/dev/null; then
    echo -e "${GREEN}✓ Namespace removed${NC}"
else
    echo -e "${YELLOW}Namespace already gone or doesn't exist${NC}"
fi

# 3. Remove leftover veth interfaces on the host
echo -e "${YELLOW}[3/9] Removing virtual network interfaces...${NC}"
sudo ip link delete veth0 2>/dev/null || true
echo -e "${GREEN}✓ Virtual interfaces removed${NC}"

# 4. Remove custom iptables rules
echo -e "${YELLOW}[4/9] Removing iptables forwarding and NAT rules...${NC}"
sudo iptables -D FORWARD -i veth0 -o $EXT_IF -j ACCEPT 2>/dev/null || true
sudo iptables -D FORWARD -i $EXT_IF -o veth0 -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || true
sudo iptables -t nat -D POSTROUTING -s 10.200.200.0/24 -o $EXT_IF -j SNAT --to-source $HOST_IP 2>/dev/null || true

echo -e "${GREEN}✓ iptables rules removed${NC}"

# 5. Clean up temporary files and logs
echo -e "${YELLOW}[5/9] Removing temporary configuration and log files...${NC}"
sudo rm -f /tmp/danted_$NS.conf
sudo rm -f /tmp/danted_$NS.log
sudo rm -f /tmp/openvpn_$NS.log
sudo rm -f /etc/netns/$NS/resolv.conf 2>/dev/null
sudo rmdir /etc/netns/$NS 2>/dev/null || true
rm -f "$CONFIG_FILE" 2>/dev/null

echo -e "${GREEN}✓ Temporary files cleaned${NC}"

# 6. Optionally disable IP forwarding (check if other processes need it)
echo -e "${YELLOW}[6/9] Checking IPv4 forwarding...${NC}"
read -p "Disable IPv4 forwarding? (Only if not needed by other services) (y/n) [n]: " DISABLE_FORWARD
DISABLE_FORWARD=${DISABLE_FORWARD:-n}

if [[ "$DISABLE_FORWARD" =~ ^[Yy]$ ]]; then
    echo 0 | sudo tee /proc/sys/net/ipv4/ip_forward > /dev/null
    echo -e "${GREEN}✓ IPv4 forwarding disabled${NC}"
else
    echo -e "${YELLOW}IPv4 forwarding left enabled${NC}"
fi

# 7. Optionally close VSCode instances that were using the proxy
echo -e "${YELLOW}[7/9] Checking for VSCode instances using the proxy...${NC}"
if pgrep -f "code.*socks5://10.200.200.2:$LOCAL_PROXY_PORT" >/dev/null 2>&1; then
    read -p "Close VSCode instances using the proxy? (y/n) [n]: " CLOSE_VSCODE
    CLOSE_VSCODE=${CLOSE_VSCODE:-n}
    
    if [[ "$CLOSE_VSCODE" =~ ^[Yy]$ ]]; then
        pkill -f "code.*socks5://10.200.200.2:$LOCAL_PROXY_PORT" 2>/dev/null || true
        echo -e "${GREEN}✓ VSCode instances closed${NC}"
    else
        echo -e "${YELLOW}VSCode instances left running${NC}"
    fi
else
    echo -e "${YELLOW}No VSCode instances found using the proxy${NC}"
fi

# 8. Verify cleanup
echo -e "${YELLOW}[8/9] Verifying cleanup...${NC}"
ISSUES=0

if sudo ip netns list | grep -q "^$NS\$"; then
    echo -e "${RED}✗ Namespace still exists${NC}"
    ISSUES=$((ISSUES+1))
fi

if ip link show veth0 >/dev/null 2>&1; then
    echo -e "${RED}✗ veth0 interface still exists${NC}"
    ISSUES=$((ISSUES+1))
fi

if pgrep -f "openvpn" >/dev/null 2>&1; then
    echo -e "${YELLOW}! OpenVPN process still running (may be from another connection)${NC}"
fi

if [ $ISSUES -eq 0 ]; then
    echo -e "${GREEN}✓ All resources successfully cleaned${NC}"
else
    echo -e "${YELLOW}! Some resources may still exist (manual cleanup may be needed)${NC}"
fi

# 9. Final summary
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           Cleanup Completed Successfully!                ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "All resources have been released:"
echo "  • Network namespace '$NS' deleted"
echo "  • Virtual interfaces (veth0/veth1, tun0) removed"
echo "  • OpenVPN, Dante, and socat processes terminated"
echo "  • iptables rules removed"
echo "  • Temporary files and logs deleted"
echo ""
echo -e "${GREEN}✓ System is now clean. You can safely re-run the connect script anytime.${NC}"
echo ""
