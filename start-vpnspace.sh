#!/bin/bash
# start-vpnspace.sh - Start isolated OpenVPN namespace with SOCKS5 proxy
# Usage: sudo ./start-vpnspace.sh <path-to-ovpn-config>

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="vpnspace"
VETH_HOST="veth_host"
VETH_NS="veth_ns"
HOST_IP="10.200.200.1"
NS_IP="10.200.200.2"
SOCKS_PORT="1080"
DANTE_CONFIG="/tmp/danted-vpnspace.conf"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run as root (use sudo)${NC}"
    exit 1
fi

# Check if config file is provided
if [ -z "$1" ]; then
    echo -e "${RED}Error: Please provide path to OpenVPN config file${NC}"
    echo "Usage: sudo $0 <path-to-ovpn-config>"
    exit 1
fi

OVPN_CONFIG="$1"

# Check if config file exists
if [ ! -f "$OVPN_CONFIG" ]; then
    echo -e "${RED}Error: OpenVPN config file not found: $OVPN_CONFIG${NC}"
    exit 1
fi

# Check for required commands
for cmd in ip openvpn danted; do
    if ! command -v $cmd &> /dev/null; then
        echo -e "${RED}Error: Required command '$cmd' not found${NC}"
        if [ "$cmd" = "danted" ]; then
            echo "Install dante-server: sudo apt-get install dante-server"
        elif [ "$cmd" = "openvpn" ]; then
            echo "Install openvpn: sudo apt-get install openvpn"
        fi
        exit 1
    fi
done

echo -e "${GREEN}=== Starting VPN Namespace ===${NC}"

# Clean up any existing namespace
echo -e "${YELLOW}Cleaning up existing namespace (if any)...${NC}"
./cleanup-vpnspace.sh 2>/dev/null || true

# Create network namespace
echo -e "${YELLOW}Creating network namespace '$NAMESPACE'...${NC}"
ip netns add $NAMESPACE

# Create veth pair
echo -e "${YELLOW}Creating virtual ethernet pair...${NC}"
ip link add $VETH_HOST type veth peer name $VETH_NS

# Move one end to namespace
ip link set $VETH_NS netns $NAMESPACE

# Configure host side
ip addr add ${HOST_IP}/24 dev $VETH_HOST
ip link set $VETH_HOST up

# Configure namespace side
ip netns exec $NAMESPACE ip addr add ${NS_IP}/24 dev $VETH_NS
ip netns exec $NAMESPACE ip link set $VETH_NS up
ip netns exec $NAMESPACE ip link set lo up

# Set up routing in namespace
ip netns exec $NAMESPACE ip route add default via $HOST_IP

# Enable IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward

# Set up NAT for namespace (temporary, will be replaced by VPN route)
iptables -t nat -A POSTROUTING -s ${NS_IP}/32 -j MASQUERADE
iptables -A FORWARD -i $VETH_HOST -j ACCEPT
iptables -A FORWARD -o $VETH_HOST -j ACCEPT

# Create Dante SOCKS5 server config
echo -e "${YELLOW}Configuring SOCKS5 proxy (port $SOCKS_PORT)...${NC}"
cat > $DANTE_CONFIG << EOF
logoutput: syslog /var/log/danted.log

# Listen on the host interface
internal: $VETH_HOST port = $SOCKS_PORT

# Route traffic through the namespace
external: $VETH_NS

clientmethod: none
socksmethod: none

client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: error
}

socks pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: error
}
EOF

# Start Dante SOCKS5 server in the namespace
echo -e "${YELLOW}Starting SOCKS5 proxy in namespace...${NC}"
ip netns exec $NAMESPACE danted -f $DANTE_CONFIG

# Start OpenVPN in the namespace
echo -e "${YELLOW}Starting OpenVPN connection in namespace...${NC}"
echo -e "${GREEN}OpenVPN will run in the background...${NC}"

# Create a PID file for OpenVPN
OVPN_PID_FILE="/tmp/vpnspace-openvpn.pid"

# Start OpenVPN in background
ip netns exec $NAMESPACE openvpn --config "$OVPN_CONFIG" --daemon --writepid $OVPN_PID_FILE

# Wait a bit for OpenVPN to establish connection
echo -e "${YELLOW}Waiting for OpenVPN to establish connection (15 seconds)...${NC}"
sleep 15

# Check if OpenVPN is running
if [ -f "$OVPN_PID_FILE" ] && kill -0 "$(cat "$OVPN_PID_FILE")" 2>/dev/null; then
    echo -e "${GREEN}✓ OpenVPN is running (PID: $(cat "$OVPN_PID_FILE"))${NC}"
else
    echo -e "${RED}✗ OpenVPN failed to start${NC}"
    echo -e "${YELLOW}Check /var/log/syslog for OpenVPN errors${NC}"
    ./cleanup-vpnspace.sh
    exit 1
fi

# Check if SOCKS proxy is accessible
if nc -z localhost $SOCKS_PORT 2>/dev/null; then
    echo -e "${GREEN}✓ SOCKS5 proxy is running on localhost:$SOCKS_PORT${NC}"
else
    echo -e "${YELLOW}⚠ SOCKS5 proxy may not be fully ready yet${NC}"
fi

echo ""
echo -e "${GREEN}=== VPN Namespace Started Successfully ===${NC}"
echo ""
echo -e "SOCKS5 proxy available at: ${GREEN}localhost:$SOCKS_PORT${NC}"
echo ""
echo -e "To launch VSCode with this proxy:"
echo -e "  ${YELLOW}./launch-vscode.sh${NC}"
echo ""
echo -e "To test the proxy:"
echo -e "  ${YELLOW}curl --socks5 localhost:$SOCKS_PORT https://ifconfig.me${NC}"
echo ""
echo -e "To stop and clean up:"
echo -e "  ${YELLOW}sudo ./cleanup-vpnspace.sh${NC}"
echo ""
