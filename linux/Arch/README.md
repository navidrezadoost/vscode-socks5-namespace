# VSCode SOCKS5 VPN Namespace - Arch Linux

## Prerequisites

This script requires the following packages to be installed:

- `openvpn` - OpenVPN client
- `dante` - SOCKS5 server (provides `sockd`)
- `socat` - Socket relay
- `curl` - For testing connectivity
- `iproute2` - Network namespace management (usually pre-installed)
- `iptables` - Firewall rules (usually pre-installed)

## Quick Installation

### Install Dependencies

```bash
sudo pacman -S openvpn dante socat curl iproute2 iptables
```

## Usage

### Connect to VPN

```bash
cd /path/to/dev-socks-isolation/linux/Arch
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

## Arch-Specific Notes

### systemd Integration

On Arch Linux, you can optionally create a systemd service for automatic startup:

```bash
sudo nano /etc/systemd/system/vscode-vpn-proxy.service
```

Add:
```ini
[Unit]
Description=VSCode VPN SOCKS5 Proxy
After=network.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/path/to/dev-socks-isolation/linux/Arch/connect.sh
ExecStop=/path/to/dev-socks-isolation/linux/Arch/disconnect.sh

[Install]
WantedBy=multi-user.target
```

### AUR Packages

If you prefer, you can install some packages from the AUR:
- `dante-server` (alternative to `dante`)

### Firewall Configuration

Arch Linux uses `iptables` by default. If you're using `nftables`, you may need to adjust the scripts or use `iptables-nft` compatibility layer.

## Troubleshooting

### Issue: "sockd: command not found"

**Solution:**
```bash
sudo pacman -S dante
```

### Issue: Permission denied

**Solution:** Ensure your user can run sudo commands:
```bash
sudo usermod -aG wheel $USER
```

### Issue: Cannot detect network interface

**Solution:** Manually specify your network interface:
```bash
ip link show
# Look for your active interface (usually starts with 'en' or 'wl')
```

## Advanced Configuration

### Custom DNS Servers

You can modify the DNS server used in the namespace by providing a different value when prompted, or by editing the script.

### Multiple Namespaces

You can run multiple isolated VPN connections by using different namespace names for each connection.

## Support

For Arch-specific issues, check:
- [Arch Wiki - OpenVPN](https://wiki.archlinux.org/title/OpenVPN)
- [Arch Wiki - Network Namespaces](https://wiki.archlinux.org/title/Linux_Containers#Namespace_isolation)
