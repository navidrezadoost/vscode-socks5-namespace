# VSCode SOCKS5 VPN Namespace - Kali Linux

## Prerequisites

Most required tools are pre-installed on Kali Linux. You may only need:

- `openvpn` - Usually pre-installed
- `dante-server` - SOCKS5 server (may need installation)
- `socat` - Usually pre-installed
- `curl` - Pre-installed
- `iproute2` - Pre-installed
- `iptables` - Pre-installed

## Quick Installation

### Install Missing Dependencies (if any)

```bash
sudo apt update
sudo apt install openvpn dante-server socat curl
```

## Usage

### Connect to VPN

```bash
cd /path/to/dev-socks-isolation/linux/Kali
chmod +x connect.sh
./connect.sh
```

The script will:
1. Show a pentesting-specific warning about traffic isolation
2. Prompt for configuration (namespace, VPN config, network settings, etc.)
3. Set up the isolated namespace
4. Launch VSCode with the proxy (if requested)

### Disconnect from VPN

```bash
./disconnect.sh
```

## Kali Linux-Specific Use Cases

### Scenario 1: Development Through VPN, Pentesting on Real IP

**Perfect for:**
- Developers in countries with internet filtering
- Need VSCode extensions/updates through VPN
- Want to test applications on local network with real IP
- Running local services accessible to colleagues

**Setup:**
```bash
# 1. Run this script to create VPN namespace for VSCode
./connect.sh

# 2. VSCode now uses VPN IP
# 3. All your pentesting tools (nmap, metasploit, burp, etc.) use real IP
# 4. Local web services accessible to team on real IP
```

### Scenario 2: Multiple VPN Connections

Run different VPN connections in different namespaces:

```bash
# Namespace 1: For VSCode (HTB VPN)
./connect.sh
# Enter namespace name: htb-vpn
# Enter OpenVPN config: /path/to/htb.ovpn

# Namespace 2: For pentesting tools (use tools like vpnutil)
# Use traditional methods or other namespace scripts
```

### Scenario 3: Developing Exploits Safely

Keep your development environment (VSCode) on a VPN while testing exploits locally:

```bash
# VSCode through VPN namespace (protected identity)
# Exploit testing in isolated lab network (real IP)
```

## Kali-Specific Notes

### Pre-installed Tools

Kali Linux comes with most networking tools pre-installed:
- `openvpn` - For VPN connections
- `iptables` - For firewall rules
- `iproute2` - For network namespaces
- `socat` - For port forwarding

You typically only need to install `dante-server`.

### Integration with Kali Tools

#### Using with Hack The Box (HTB)

```bash
# Connect VSCode to regular internet through VPN
./connect.sh
# Use your HTB .ovpn file

# Your HTB connection for pentesting (separate)
sudo openvpn /path/to/htb-lab.ovpn
# This runs normally on host
```

#### Using with TryHackMe (THM)

Same principle - VSCode isolated in namespace, THM VPN on host.

#### Using with Burp Suite

Burp Suite runs on the host with your real IP, while VSCode uses the namespace VPN.

### Proxychains Integration

You can combine this with proxychains for more complex routing:

```bash
# In the namespace
sudo ip netns exec vpnspace bash

# Now in namespace shell
proxychains4 <your-command>
```

### systemd Service

Create a service to auto-connect VSCode VPN on boot:

```bash
sudo nano /etc/systemd/system/vscode-vpn.service
```

Add:
```ini
[Unit]
Description=VSCode VPN SOCKS5 Proxy
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/path/to/dev-socks-isolation/linux/Kali/connect.sh
ExecStop=/path/to/dev-socks-isolation/linux/Kali/disconnect.sh
StandardInput=tty-force

[Install]
WantedBy=multi-user.target
```

## Troubleshooting

### Issue: Multiple OpenVPN instances conflicting

**Solution:** Use different config files and namespace names for each VPN connection.

### Issue: Can't access local network services from namespace

**Expected behavior:** The namespace is isolated. To access local services:

```bash
# From within the namespace
sudo ip netns exec vpnspace curl http://10.200.200.1:8000
# 10.200.200.1 is the host side of the veth pair
```

### Issue: Kali's default VPN manager conflicts

**Solution:** This script creates a separate namespace and won't conflict with Kali's default VPN connections.

### Issue: dante-server not starting

**Check logs:**
```bash
sudo ip netns exec vpnspace cat /tmp/danted_vpnspace.log
```

**Common fix:**
```bash
# Ensure dante-server is installed
sudo apt install dante-server

# Check if binary is sockd or danted
which sockd || which danted
```

## Advanced Configuration

### Running Specific Tools in the Namespace

To run a specific tool through the VPN namespace:

```bash
# Execute command in namespace
sudo ip netns exec vpnspace <command>

# Example: Run curl through VPN
sudo ip netns exec vpnspace curl https://api.ipify.org

# Example: Run nmap through VPN
sudo ip netns exec vpnspace nmap -sV target.com
```

### Creating Aliases for Namespace Commands

```bash
# Add to ~/.zshrc or ~/.bashrc
alias vpn-exec='sudo ip netns exec vpnspace'
alias vpn-shell='sudo ip netns exec vpnspace bash'

# Usage
vpn-exec curl https://api.ipify.org
vpn-shell  # Interactive shell in namespace
```

### Split Tunneling

This script IS split tunneling - VSCode through VPN, everything else through real IP.

## Security Considerations

### For Penetration Testers

- **Identity Protection**: VSCode traffic is routed through VPN, protecting your development identity
- **Traffic Separation**: Pentesting traffic remains on real IP (or separate VPN)
- **No Traffic Mixing**: Different activities use different IP addresses
- **Audit Trail**: Clear separation helps with logging and compliance

### For Developers in Restricted Countries

- **Development Freedom**: Access VSCode extensions and GitHub through VPN
- **Local Testing**: Test applications on local network with real IP
- **Team Collaboration**: Colleagues can access your local services
- **No Performance Impact**: Only VSCode traffic goes through VPN

## Support

For Kali-specific issues:
- [Kali Linux Forums](https://forums.kali.org/)
- [Kali Linux Documentation](https://www.kali.org/docs/)
- [Kali Linux OpenVPN Guide](https://www.kali.org/docs/general-use/openvpn/)
