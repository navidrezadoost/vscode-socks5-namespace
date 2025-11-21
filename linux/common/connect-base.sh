#!/bin/bash
# VSCode/JetBrains SOCKS5 Namespace - Base Connect Script
# Creates an isolated network namespace for OpenVPN + SOCKS5 proxy
# This allows VSCode and JetBrains IDEs to use VPN while keeping host IP unchanged

set -e

# Color codes for better UX
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  VSCode/JetBrains SOCKS5 VPN Namespace Setup            ║${NC}"
echo -e "${GREEN}║  Isolated OpenVPN for IDEs (VSCode, IntelliJ, PyCharm)  ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Function to detect network interface
detect_network_interface() {
    # Get the default route interface
    ip route | grep default | awk '{print $5}' | head -1
}

# Function to detect host IP
detect_host_ip() {
    local interface=$1
    ip addr show "$interface" | grep "inet " | awk '{print $2}' | cut -d/ -f1 | head -1
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for required dependencies
echo -e "${YELLOW}Checking dependencies...${NC}"
MISSING_DEPS=()

for cmd in openvpn socat curl iptables ip; do
    if ! command_exists "$cmd"; then
        MISSING_DEPS+=("$cmd")
    fi
done

# Check for Dante SOCKS server (sockd)
if ! command_exists sockd && ! command_exists danted; then
    MISSING_DEPS+=("dante-server")
fi

if [ ${#MISSING_DEPS[@]} -ne 0 ]; then
    echo -e "${RED}Error: Missing required dependencies: ${MISSING_DEPS[*]}${NC}"
    echo -e "${YELLOW}Please install them using your package manager and try again.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ All dependencies found${NC}\n"

# Collect configuration from user
echo -e "${YELLOW}Configuration Setup${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Namespace name
read -p "Enter namespace name [vpnspace]: " NS
NS=${NS:-vpnspace}

# OpenVPN config
while true; do
    read -p "Enter full path to your OpenVPN config file: " OVPN_CONFIG
    if [ -f "$OVPN_CONFIG" ]; then
        break
    else
        echo -e "${RED}File not found. Please enter a valid path.${NC}"
    fi
done

# Auto-detect network interface
DEFAULT_IF=$(detect_network_interface)
read -p "Enter your main network interface [$DEFAULT_IF]: " EXT_IF
EXT_IF=${EXT_IF:-$DEFAULT_IF}

# Auto-detect host IP
DEFAULT_IP=$(detect_host_ip "$EXT_IF")
read -p "Enter your host IP address [$DEFAULT_IP]: " HOST_IP
HOST_IP=${HOST_IP:-$DEFAULT_IP}

# SOCKS port (internal to namespace)
read -p "Enter SOCKS5 port inside namespace [1080]: " SOCKS_PORT
SOCKS_PORT=${SOCKS_PORT:-1080}

# Local proxy port (exposed to host)
read -p "Enter local proxy port (exposed to host) [1081]: " LOCAL_PROXY_PORT
LOCAL_PROXY_PORT=${LOCAL_PROXY_PORT:-1081}

# DNS server
read -p "Enter DNS server for namespace [8.8.8.8]: " DNS_SERVER
DNS_SERVER=${DNS_SERVER:-8.8.8.8}

# Launch VSCode option
read -p "Launch VSCode with proxy after setup? (y/n) [y]: " LAUNCH_VSCODE
LAUNCH_VSCODE=${LAUNCH_VSCODE:-y}

echo ""
echo -e "${GREEN}Configuration Summary:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Namespace:              $NS"
echo "OpenVPN Config:         $OVPN_CONFIG"
echo "Network Interface:      $EXT_IF"
echo "Host IP:                $HOST_IP"
echo "SOCKS Port (internal):  $SOCKS_PORT"
echo "Local Proxy Port:       $LOCAL_PROXY_PORT"
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

# 1. Full cleanup of previous instances
echo -e "${YELLOW}[1/14] Cleaning up previous instances...${NC}"
sudo pkill -f "openvpn.*$(basename $OVPN_CONFIG)" 2>/dev/null || true
sudo pkill -f "sockd" 2>/dev/null || true
sudo pkill -f "danted" 2>/dev/null || true
sudo pkill -f "socat.*$LOCAL_PROXY_PORT" 2>/dev/null || true
sudo ip netns delete $NS 2>/dev/null || true
sudo ip link delete veth0 2>/dev/null || true
sudo iptables -t nat -D POSTROUTING -s 10.200.200.0/24 -o $EXT_IF -j SNAT --to-source $HOST_IP 2>/dev/null || true
sudo iptables -D FORWARD -i veth0 -o $EXT_IF -j ACCEPT 2>/dev/null || true
sudo iptables -D FORWARD -i $EXT_IF -o veth0 -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || true
sleep 1

# 2. Create network namespace and enable loopback
echo -e "${YELLOW}[2/14] Creating network namespace '$NS'...${NC}"
sudo ip netns add $NS
sudo ip netns exec $NS ip link set dev lo up

# 3. Create veth pair and configure addressing/routing
echo -e "${YELLOW}[3/14] Setting up virtual network interfaces...${NC}"
sudo ip link add veth0 type veth peer name veth1
sudo ip link set veth0 up
sudo ip link set veth1 netns $NS up
sudo ip addr add 10.200.200.1/24 dev veth0
sudo ip netns exec $NS ip addr add 10.200.200.2/24 dev veth1
sudo ip netns exec $NS ip route add default via 10.200.200.1 dev veth1

# 4. Enable IPv4 forwarding and set up NAT/forwarding rules
echo -e "${YELLOW}[4/14] Configuring IPv4 forwarding and NAT rules...${NC}"
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward > /dev/null
sudo iptables -A FORWARD -i veth0 -o $EXT_IF -j ACCEPT
sudo iptables -A FORWARD -i $EXT_IF -o veth0 -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -t nat -A POSTROUTING -s 10.200.200.0/24 -o $EXT_IF -j SNAT --to-source $HOST_IP

# 5. Configure DNS for the namespace
echo -e "${YELLOW}[5/14] Configuring DNS...${NC}"
sudo mkdir -p /etc/netns/$NS
echo "nameserver $DNS_SERVER" | sudo tee /etc/netns/$NS/resolv.conf > /dev/null

# 6. Generate Dante SOCKS5 server configuration
echo -e "${YELLOW}[6/14] Generating SOCKS5 server configuration...${NC}"
DANTE_CONF="/tmp/danted_$NS.conf"
sudo tee $DANTE_CONF > /dev/null <<EOF
logoutput: /tmp/danted_$NS.log
internal: 0.0.0.0 port = $SOCKS_PORT
external: tun0
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

# 7. Start OpenVPN inside the namespace
echo -e "${YELLOW}[7/14] Connecting to VPN...${NC}"
sudo ip netns exec $NS openvpn --config $OVPN_CONFIG --daemon --log /tmp/openvpn_$NS.log

# 8. Wait for tun0 interface to appear and obtain IP
echo -e "${YELLOW}[8/14] Waiting for VPN connection...${NC}"
VPN_CONNECTED=false
for i in {1..30}; do
    if sudo ip netns exec $NS ip addr show tun0 2>/dev/null | grep -q "inet"; then
        VPN_IP=$(sudo ip netns exec $NS ip addr show tun0 | grep "inet " | awk '{print $2}' | cut -d/ -f1 | head -1)
        echo -e "${GREEN}✓ VPN connected successfully! Assigned IP: $VPN_IP${NC}"
        VPN_CONNECTED=true
        break
    fi
    echo -n "."
    sleep 1
done
echo ""

# Verify tun0 was actually created
if [ "$VPN_CONNECTED" = false ] || ! sudo ip netns exec $NS ip addr show tun0 >/dev/null 2>&1; then
    echo -e "${RED}Error: VPN connection failed! tun0 interface was not created.${NC}"
    echo -e "${YELLOW}Check OpenVPN logs: /tmp/openvpn_$NS.log${NC}"
    exit 1
fi

# 9. Start Dante SOCKS5 server inside the namespace
echo -e "${YELLOW}[9/14] Starting SOCKS5 proxy server...${NC}"
# Try sockd first, then danted
if command_exists sockd; then
    sudo ip netns exec $NS sockd -f $DANTE_CONF -D 2>/dev/null &
elif command_exists danted; then
    sudo ip netns exec $NS danted -f $DANTE_CONF -D 2>/dev/null &
else
    echo -e "${RED}Error: Neither sockd nor danted found!${NC}"
    exit 1
fi
sleep 3

# 10. Test SOCKS5 proxy from inside the namespace
echo -e "${YELLOW}[10/14] Testing proxy from inside namespace...${NC}"
NS_IP=$(sudo ip netns exec $NS curl -s --connect-timeout 10 --socks5-hostname 127.0.0.1:$SOCKS_PORT https://api.ipify.org 2>/dev/null)
if [[ -n "$NS_IP" ]]; then
    echo -e "${GREEN}✓ Proxy working inside namespace! Public IP: $NS_IP${NC}"
else
    echo -e "${RED}Error: Proxy failed inside namespace${NC}"
    echo -e "${YELLOW}Dante server log:${NC}"
    sudo ip netns exec $NS cat /tmp/danted_$NS.log 2>/dev/null || echo "Log file not found"
    exit 1
fi

# 11. Expose SOCKS5 port to host via socat tunnel
echo -e "${YELLOW}[11/14] Creating tunnel to expose proxy to host...${NC}"
sudo ip netns exec $NS socat TCP-LISTEN:$LOCAL_PROXY_PORT,bind=10.200.200.2,reuseaddr,fork TCP:127.0.0.1:$SOCKS_PORT &
sleep 2

# 12. Test proxy accessibility from the host
echo -e "${YELLOW}[12/14] Testing proxy from host system...${NC}"
HOST_IP_TEST=$(curl -s --connect-timeout 10 --socks5-hostname 10.200.200.2:$LOCAL_PROXY_PORT https://api.ipify.org 2>/dev/null)
if [[ -n "$HOST_IP_TEST" ]]; then
    echo -e "${GREEN}✓ Proxy successfully accessible from host! Public IP: $HOST_IP_TEST${NC}"
else
    echo -e "${RED}Error: Proxy not reachable from host${NC}"
    echo -e "${YELLOW}Testing basic connectivity inside namespace...${NC}"
    sudo ip netns exec $NS ping -c 2 8.8.8.8
    exit 1
fi

# Additional verification for JetBrains plugins site
echo -e "${YELLOW}[12.1/14] Testing JetBrains plugins site...${NC}"
JETBRAINS_TEST=$(curl -s --connect-timeout 10 --socks5-hostname 10.200.200.2:$LOCAL_PROXY_PORT https://plugins.jetbrains.com/ 2>/dev/null | head -c 100)
if [[ -n "$JETBRAINS_TEST" ]]; then
    echo -e "${GREEN}✓ JetBrains plugins site accessible through proxy!${NC}"
else
    echo -e "${YELLOW}Note: JetBrains plugins site test inconclusive (may still work)${NC}"
fi

# 13. Save configuration for disconnect script
echo -e "${YELLOW}[13/14] Saving configuration...${NC}"
CONFIG_FILE="/tmp/vpnns_${NS}_config.sh"
cat > $CONFIG_FILE <<EOF
# Auto-generated configuration for VPN namespace
NS="$NS"
LOCAL_PROXY_PORT=$LOCAL_PROXY_PORT
EXT_IF="$EXT_IF"
HOST_IP="$HOST_IP"
OVPN_CONFIG="$OVPN_CONFIG"
EOF

# 14. Final status summary
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              Setup Completed Successfully!               ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Proxy Configuration:${NC}"
echo "  SOCKS5 Address:  socks5://10.200.200.2:$LOCAL_PROXY_PORT"
echo "  VPN Public IP:   $NS_IP"
echo "  Host IP:         $HOST_IP (unchanged)"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}           IDE Configuration Instructions${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}▶ VSCode Configuration:${NC}"
echo "  Launch with proxy:"
echo "    code --proxy-server=\"socks5://10.200.200.2:$LOCAL_PROXY_PORT\""
echo ""
echo -e "${YELLOW}▶ JetBrains IDEs (IntelliJ, PyCharm, WebStorm, DataGrip, etc.):${NC}"
echo ""
echo "  ${GREEN}Method 1: Manual SOCKS Proxy (Recommended)${NC}"
echo "    1. Open your JetBrains IDE"
echo "    2. File → Settings → Appearance & Behavior → System Settings → HTTP Proxy"
echo "    3. Select 'Manual proxy configuration'"
echo "    4. Select 'SOCKS' (not HTTP/HTTPS)"
echo "    5. Host name: 10.200.200.2"
echo "    6. Port number: $LOCAL_PROXY_PORT"
echo "    7. SOCKS Proxy: Check this box"
echo "    8. Click 'Check connection' with URL: https://plugins.jetbrains.com"
echo "    9. Apply and restart IDE"
echo ""
echo "  ${GREEN}Method 2: Auto-detect proxy settings${NC}"
echo "    1. Select 'Auto-detect proxy settings'"
echo "    2. IDE may automatically detect the SOCKS5 proxy"
echo ""
echo "  ${GREEN}Method 3: Launch with JVM argument (Alternative)${NC}"
echo "    Add to idea.vmoptions or similar:"
echo "      -Djava.net.socks.host=10.200.200.2"
echo "      -Djava.net.socks.port=$LOCAL_PROXY_PORT"
echo ""
echo -e "${YELLOW}▶ Testing the connection:${NC}"
echo "  From terminal:"
echo "    curl --socks5 10.200.200.2:$LOCAL_PROXY_PORT https://plugins.jetbrains.com"
echo ""
echo -e "${YELLOW}To disconnect:${NC}"
echo "  Run the disconnect script for your distribution"
echo ""

# 15. Launch VSCode with the isolated proxy
if [[ "$LAUNCH_VSCODE" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}[14/14] Launching VSCode with isolated SOCKS5 proxy...${NC}"
    if command_exists code; then
        code --proxy-server="socks5://10.200.200.2:$LOCAL_PROXY_PORT" &
        echo -e "${GREEN}✓ VSCode launched${NC}"
    else
        echo -e "${YELLOW}Warning: VSCode (code command) not found in PATH${NC}"
        echo "You can manually launch it with: code --proxy-server=\"socks5://10.200.200.2:$LOCAL_PROXY_PORT\""
    fi
fi

echo ""
echo -e "${GREEN}✓ All done!${NC}"
