# VSCode SOCKS5 VPN Namespace - Ubuntu

## Prerequisites

This script requires the following packages to be installed:

- `openvpn` - OpenVPN client
- `dante-server` - SOCKS5 server (provides `danted`)
- `socat` - Socket relay
- `curl` - For testing connectivity
- `iproute2` - Network namespace management (usually pre-installed)
- `iptables` - Firewall rules (usually pre-installed)

## Quick Installation

### Install Dependencies

```bash
sudo apt update
sudo apt install openvpn dante-server socat curl iproute2 iptables
```

## Usage

### Connect to VPN

```bash
cd /path/to/dev-socks-isolation/linux/Ubuntu
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

## Ubuntu-Specific Notes

### Ubuntu 20.04 LTS and Later

Ubuntu 20.04+ uses `systemd-resolved` for DNS management. The script handles this automatically by creating namespace-specific DNS configuration in `/etc/netns/`.

### AppArmor Considerations

Ubuntu uses AppArmor for security. If you encounter permission issues with OpenVPN, you may need to adjust the AppArmor profile:

```bash
sudo aa-complain /usr/sbin/openvpn
```

Or disable AppArmor for OpenVPN (not recommended for production):
```bash
sudo ln -s /etc/apparmor.d/usr.sbin.openvpn /etc/apparmor.d/disable/
sudo apparmor_parser -R /etc/apparmor.d/usr.sbin.openvpn
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
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/path/to/dev-socks-isolation/linux/Ubuntu/connect.sh
ExecStop=/path/to/dev-socks-isolation/linux/Ubuntu/disconnect.sh
StandardInput=tty-force
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

Then enable it:
```bash
sudo systemctl daemon-reload
sudo systemctl enable vscode-vpn-proxy.service
```

## Compatibility

This script is compatible with:
- Ubuntu (20.04 LTS, 22.04 LTS, 24.04 LTS and newer)
- Linux Mint (20, 21, 22)
- Pop!_OS (20.04, 22.04 and newer)
- Zorin OS (16, 17)
- Elementary OS
- Other Ubuntu-based distributions

## Troubleshooting

### Issue: "danted: command not found" or "sockd: command not found"

**Solution:**
```bash
sudo apt install dante-server
```

Note: On Ubuntu/Debian, the Dante server binary might be called `danted` instead of `sockd`.

### Issue: DNS not working in namespace

**Solution:** Check if systemd-resolved is running:
```bash
systemctl status systemd-resolved
```

If it's active, the script should handle DNS automatically. If not, you can manually set DNS servers.

### Issue: "Operation not permitted" errors

**Solution:** Ensure your user has sudo privileges:
```bash
sudo usermod -aG sudo $USER
```

Then log out and log back in.

### Issue: Network interface not detected

**Solution:** List your network interfaces:
```bash
ip link show
# Common names: eth0, enp*, wlp* (wifi)
```

### Issue: UFW Firewall blocking connections

If you're using UFW (Ubuntu's default firewall), you may need to allow forwarding:

```bash
sudo ufw allow from 10.200.200.0/24
sudo ufw route allow from 10.200.200.0/24
```

## Advanced Configuration

### Using with Network Manager

If you're using NetworkManager's OpenVPN plugin, you can still use this script with manually exported .ovpn files.

### Custom DNS Servers

For better privacy, consider using:
- Cloudflare: 1.1.1.1
- Quad9: 9.9.9.9
- OpenDNS: 208.67.222.222

### Multiple VPN Connections

You can run multiple isolated VPN connections simultaneously by using different namespace names.

## Support

For Ubuntu-specific issues, check:
- [Ubuntu OpenVPN Documentation](https://help.ubuntu.com/community/OpenVPN)
- [Ubuntu Network Namespaces](https://ubuntu.com/server/docs/network-namespaces)
