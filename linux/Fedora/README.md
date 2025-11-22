# VSCode SOCKS5 VPN Namespace - Fedora

## Prerequisites

This script requires the following packages to be installed:

- `openvpn` - OpenVPN client
- `dante-server` - SOCKS5 server (provides `sockd`)
- `socat` - Socket relay
- `curl` - For testing connectivity
- `iproute` - Network namespace management (usually pre-installed)
- `iptables` - Firewall rules (usually pre-installed)

## Quick Installation

### Install Dependencies

**For Fedora:**
```bash
sudo dnf install openvpn dante-server socat curl iproute iptables
```

**For RHEL/CentOS (with EPEL repository):**
```bash
# Enable EPEL repository first
sudo dnf install epel-release
# Then install packages
sudo dnf install openvpn dante-server socat curl iproute iptables
```

## Usage

### Connect to VPN

```bash
cd /path/to/dev-socks-isolation/linux/Fedora
chmod +x connect.sh
./connect.sh
```

The script will prompt you for:
- Namespace name (default: vpnspace)
- Path to your OpenVPN config file (.ovpn)
- Network interface (auto-detected)
- Host IP address (auto-detected)
- SOCKS5 ports configuration
- DNS server (default: 8.8.8.8)
- Whether to launch VSCode automatically

### Disconnect from VPN

```bash
./disconnect.sh
```

## Fedora/RHEL-Specific Notes

### SELinux Considerations

Fedora and RHEL use SELinux for security. The script will detect if SELinux is in Enforcing mode.

If you encounter permission issues:

**Temporary solution (for testing):**
```bash
sudo setenforce 0  # Set to Permissive mode
```

**Permanent solution (create proper policy):**
```bash
# Generate a policy from audit logs
sudo grep openvpn /var/log/audit/audit.log | audit2allow -M myvpn
sudo semodule -i myvpn.pp
```

**Or disable SELinux for OpenVPN (not recommended):**
```bash
sudo setsebool -P openvpn_can_network_connect 1
```

### firewalld Integration

Fedora uses `firewalld` instead of directly managing iptables. The script adds iptables rules that work alongside firewalld.

To properly integrate with firewalld:

```bash
# Allow traffic from the VPN namespace
sudo firewall-cmd --permanent --zone=trusted --add-source=10.200.200.0/24
sudo firewall-cmd --permanent --zone=public --add-masquerade
sudo firewall-cmd --reload
```

Or create a custom zone:
```bash
sudo firewall-cmd --permanent --new-zone=vpnnamespace
sudo firewall-cmd --permanent --zone=vpnnamespace --add-source=10.200.200.0/24
sudo firewall-cmd --permanent --zone=vpnnamespace --set-target=ACCEPT
sudo firewall-cmd --reload
```

### systemd Service

Create a systemd service for automatic startup:

```bash
sudo nano /etc/systemd/system/vscode-vpn-proxy.service
```

Add:
```ini
[Unit]
Description=VSCode VPN SOCKS5 Proxy
After=network-online.target firewalld.service
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/path/to/dev-socks-isolation/linux/Fedora/connect.sh
ExecStop=/path/to/dev-socks-isolation/linux/Fedora/disconnect.sh
StandardInput=tty-force

[Install]
WantedBy=multi-user.target
```

## Compatibility

This script is compatible with:
- Fedora (37, 38, 39, 40 and newer)
- RHEL (8, 9)
- CentOS Stream (8, 9)
- Rocky Linux (8, 9)
- AlmaLinux (8, 9)
- Other RHEL-based distributions

## Troubleshooting

### Issue: "dante-server not found in repositories"

**Solution for RHEL/CentOS:** Enable EPEL repository:
```bash
sudo dnf install epel-release
sudo dnf update
sudo dnf install dante-server
```

### Issue: SELinux denying permissions

**Check audit logs:**
```bash
sudo ausearch -m avc -ts recent
```

**Generate and install policy:**
```bash
sudo ausearch -m avc -ts recent | audit2allow -M mynetns
sudo semodule -i mynetns.pp
```

### Issue: firewalld blocking connections

**Check firewalld status:**
```bash
sudo firewall-cmd --list-all
```

**Allow the namespace network:**
```bash
sudo firewall-cmd --permanent --zone=trusted --add-source=10.200.200.0/24
sudo firewall-cmd --reload
```

### Issue: "Operation not permitted" when creating namespace

**Solution:** Ensure your user has sudo privileges:
```bash
sudo usermod -aG wheel $USER
```

Then log out and log back in.

### Issue: Network Manager interfering with VPN

If Network Manager is managing your VPN connections, you may need to disable it for OpenVPN:

```bash
# List all connections
nmcli connection show

# Disable NetworkManager for specific connection (if needed)
nmcli connection modify <connection-name> connection.autoconnect no
```

## Advanced Configuration

### Using with DNF System Upgrades

This script is compatible with Fedora's DNF system upgrade process. However, you should disconnect the VPN namespace before performing major system upgrades.

### Custom DNS with systemd-resolved

Fedora uses systemd-resolved for DNS. The script creates namespace-specific DNS configuration that overrides the system default.

### Multiple Namespaces

You can run multiple isolated VPN connections by using different namespace names for each connection.

## Support

For Fedora/RHEL-specific issues, check:
- [Fedora OpenVPN Documentation](https://docs.fedoraproject.org/en-US/quick-docs/getting-started-with-openvpn/)
- [RHEL Network Namespaces](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/configuring_and_managing_networking/index)
- [SELinux Troubleshooting](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/using_selinux/index)
