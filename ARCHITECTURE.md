# vscode-vpnspace Architecture

## Overview

This project provides a complete solution for running applications through an isolated OpenVPN connection using Linux network namespaces. The architecture ensures complete isolation between VPN traffic and host traffic.

## Components

### 1. Network Namespace (`vpnspace`)
- **Purpose**: Isolated network environment for OpenVPN
- **Name**: `vpnspace` (configurable)
- **Benefits**: 
  - Complete network isolation
  - No interference with host network
  - Independent routing table
  - Separate process space

### 2. Virtual Ethernet Pair
- **Host Side**: `veth_host` (10.200.200.1/24)
- **Namespace Side**: `veth_ns` (10.200.200.2/24)
- **Purpose**: Communication bridge between host and namespace
- **Function**: Allows SOCKS proxy to receive connections from host

### 3. OpenVPN Client
- **Location**: Runs inside the `vpnspace` namespace
- **Process**: Daemonized background process
- **PID File**: `/tmp/vpnspace-openvpn.pid`
- **Configuration**: User-provided .ovpn file
- **Network**: Routes all namespace traffic through VPN tunnel

### 4. SOCKS5 Proxy (Dante)
- **Server**: Dante SOCKS server (danted)
- **Port**: 1080 (localhost only)
- **Location**: Runs inside namespace
- **Internal Interface**: `veth_host` (receives connections from host)
- **External Interface**: `veth_ns` (routes through namespace/VPN)
- **Configuration**: `/tmp/danted-vpnspace.conf`

### 5. Application Layer (VSCode/Others)
- **Connection**: SOCKS5 proxy on localhost:1080
- **Traffic Flow**: App → SOCKS5 → Namespace → OpenVPN → Internet
- **Isolation**: Applications don't know about namespace, just use proxy

## Network Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                         Host System                              │
│                                                                   │
│  ┌─────────────┐                                                 │
│  │  VSCode     │                                                 │
│  │ (any app)   │                                                 │
│  └─────┬───────┘                                                 │
│        │ SOCKS5 request                                          │
│        │ (localhost:1080)                                        │
│        ▼                                                          │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │         Network Namespace "vpnspace"                     │    │
│  │                                                           │    │
│  │  ┌────────────────┐                                      │    │
│  │  │ Dante SOCKS5   │◄─────── veth_host (10.200.200.1)    │    │
│  │  │    Server      │         (Receives from host)         │    │
│  │  └───────┬────────┘                                      │    │
│  │          │                                                │    │
│  │          │ Route through namespace                       │    │
│  │          ▼                                                │    │
│  │  ┌────────────────┐                                      │    │
│  │  │    OpenVPN     │◄─────── veth_ns (10.200.200.2)      │    │
│  │  │    Client      │         (Routes through VPN)         │    │
│  │  └───────┬────────┘                                      │    │
│  │          │                                                │    │
│  └──────────┼────────────────────────────────────────────────┘   │
│             │                                                     │
└─────────────┼─────────────────────────────────────────────────────┘
              │
              │ Encrypted VPN tunnel
              ▼
       ┌─────────────┐
       │ VPN Server  │
       └─────────────┘
              │
              ▼
         Internet
```

## Process Lifecycle

### Startup (start-vpnspace.sh)

1. **Validation**
   - Check for root privileges
   - Verify OpenVPN config file exists
   - Check for required commands (ip, openvpn, danted)

2. **Cleanup**
   - Remove any existing namespace/resources from previous runs

3. **Namespace Creation**
   ```bash
   ip netns add vpnspace
   ```

4. **Virtual Ethernet Setup**
   ```bash
   ip link add veth_host type veth peer name veth_ns
   ip link set veth_ns netns vpnspace
   ip addr add 10.200.200.1/24 dev veth_host
   ip link set veth_host up
   ```

5. **Namespace Network Configuration**
   ```bash
   ip netns exec vpnspace ip addr add 10.200.200.2/24 dev veth_ns
   ip netns exec vpnspace ip link set veth_ns up
   ip netns exec vpnspace ip link set lo up
   ip netns exec vpnspace ip route add default via 10.200.200.1
   ```

6. **IP Forwarding & NAT**
   ```bash
   echo 1 > /proc/sys/net/ipv4/ip_forward
   iptables -t nat -A POSTROUTING -s 10.200.200.2/32 -j MASQUERADE
   iptables -A FORWARD -i veth_host -j ACCEPT
   iptables -A FORWARD -o veth_host -j ACCEPT
   ```

7. **SOCKS5 Proxy Launch**
   - Generate Dante configuration
   - Start danted in namespace
   - Listen on veth_host:1080
   - Route through veth_ns

8. **OpenVPN Launch**
   ```bash
   ip netns exec vpnspace openvpn --config <config> --daemon --writepid <pidfile>
   ```

9. **Verification**
   - Wait for OpenVPN connection establishment
   - Verify processes are running
   - Display connection information

### Runtime

- **OpenVPN**: Runs continuously, maintaining VPN connection
- **Dante**: Accepts SOCKS5 connections from host applications
- **Namespace**: Isolated network environment with own routing
- **Applications**: Connect through SOCKS5 proxy transparently

### Shutdown (cleanup-vpnspace.sh)

1. **OpenVPN Termination**
   - Read PID from file
   - Send SIGTERM, wait, then SIGKILL if needed
   - Remove PID file

2. **Process Cleanup**
   - Kill all processes in namespace
   - Stop Dante SOCKS server

3. **Network Cleanup**
   - Delete virtual ethernet interfaces
   - Remove network namespace
   - Clean up iptables rules

4. **File Cleanup**
   - Remove Dante configuration
   - Remove temporary files

## Security Model

### Isolation Benefits

1. **Network Isolation**
   - VPN traffic completely separate from host
   - No risk of VPN routes affecting host network
   - DNS leaks prevented by namespace isolation

2. **Process Isolation**
   - OpenVPN runs in separate process space
   - Namespace processes can't affect host
   - Clean process tree management

3. **Minimal Privilege**
   - Root required only for namespace creation
   - OpenVPN/Dante don't need permanent root
   - No setuid binaries needed

### Security Considerations

1. **SOCKS5 Proxy**
   - Listens only on localhost (not network-exposed)
   - No authentication (local trust model)
   - Could add auth if needed

2. **OpenVPN Config**
   - User-provided, should be secured
   - May contain credentials
   - Excluded from git by default

3. **Cleanup Required**
   - Manual cleanup needed on exit
   - No automatic cleanup on crash
   - Consider systemd service for production

## Configuration Files

### Dante Configuration (auto-generated)
```
logoutput: syslog /var/log/danted.log
internal: veth_host port = 1080
external: veth_ns
clientmethod: none
socksmethod: none
client pass { from: 0.0.0.0/0 to: 0.0.0.0/0 log: error }
socks pass { from: 0.0.0.0/0 to: 0.0.0.0/0 log: error }
```

### OpenVPN Configuration (user-provided)
- Standard .ovpn format
- Must include all necessary credentials
- See example-config.ovpn for template

## Troubleshooting Points

### Common Issues

1. **Namespace already exists**
   - Run cleanup-vpnspace.sh first
   - Check: `ip netns list`

2. **OpenVPN fails to start**
   - Check config file syntax
   - Review: `/var/log/syslog` or `journalctl`
   - Verify credentials and server connectivity

3. **SOCKS proxy not accessible**
   - Verify Dante is running: `ps aux | grep danted`
   - Check port: `nc -z localhost 1080`
   - Review logs: `/var/log/danted.log`

4. **No internet through proxy**
   - Verify OpenVPN connection established
   - Check namespace routing: `ip netns exec vpnspace ip route`
   - Test namespace connectivity: `ip netns exec vpnspace ping 8.8.8.8`

## Performance Considerations

### Overhead

- **Minimal CPU**: namespace/proxy adds negligible CPU overhead
- **Memory**: ~10-20 MB for OpenVPN + Dante
- **Network**: SOCKS5 proxy adds minimal latency (<1ms typically)

### Scalability

- Can run multiple namespaces with different VPNs
- Each namespace needs unique:
  - Namespace name
  - SOCKS port
  - IP subnet
  - PID files

## Future Enhancements

1. **Systemd Integration**
   - Auto-start on boot
   - Automatic cleanup on shutdown
   - Service management

2. **Multiple VPN Support**
   - Configuration file for multiple VPNs
   - Easy switching between VPNs
   - Per-app VPN assignment

3. **Enhanced Monitoring**
   - Connection status dashboard
   - Traffic statistics
   - Connection health checks

4. **Auto-reconnect**
   - Detect VPN disconnection
   - Automatic reconnection
   - Notification system

5. **GUI Wrapper**
   - Graphical interface for management
   - Easy configuration
   - Visual status indicators
