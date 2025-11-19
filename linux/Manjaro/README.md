# VSCode SOCKS5 VPN Namespace - Manjaro Linux

## Prerequisites

This script requires the following packages to be installed:

- `openvpn` - OpenVPN client
- `dante` - SOCKS5 server (provides `sockd`)
- `socat` - Socket relay
- `curl` - For testing connectivity
- `iproute2` - Network namespace management (usually pre-installed)
- `iptables` - Firewall rules (usually pre-installed)

## Quick Installation

### Using pacman (recommended)

```bash
sudo pacman -S openvpn dante socat curl iproute2 iptables
```

### Using Pamac (GUI)

1. Open Pamac (Add/Remove Software)
2. Search for and install:
   - openvpn
   - dante
   - socat
   - curl

### Using yay (AUR helper)

```bash
yay -S openvpn dante socat curl
```

## Usage

### Connect to VPN

```bash
cd /path/to/vscode-socks5-namespace/linux/Manjaro
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

## Manjaro-Specific Notes

### Package Management

Manjaro offers multiple ways to install packages:

#### Command Line (pacman)
```bash
sudo pacman -S <package-name>
```

#### Graphical (Pamac)
- Open "Add/Remove Software"
- Search and install packages
- Supports both official repos and AUR

#### AUR (Arch User Repository)
Install yay if not already installed:
```bash
sudo pacman -S yay
```

Then use yay for AUR packages:
```bash
yay -S <package-name>
```

### Firewall Configuration

Manjaro may use either UFW or firewalld:

#### For UFW (most common on Manjaro)

```bash
# Check if UFW is active
sudo ufw status

# Allow traffic from VPN namespace
sudo ufw allow from 10.200.200.0/24

# Enable UFW if not enabled
sudo ufw enable
```

#### For firewalld

```bash
# Allow traffic from the VPN namespace
sudo firewall-cmd --permanent --zone=trusted --add-source=10.200.200.0/24
sudo firewall-cmd --permanent --zone=public --add-masquerade
sudo firewall-cmd --reload
```

### Desktop Environment Considerations

Manjaro supports multiple desktop environments. The script works with all of them:

- **KDE Plasma** - Default for Manjaro KDE
- **XFCE** - Default for Manjaro XFCE
- **GNOME** - Default for Manjaro GNOME
- **i3** - Community edition
- **Cinnamon** - Community edition

### Network Manager Integration

Manjaro uses NetworkManager by default. This script creates a separate namespace and won't conflict with NetworkManager's VPN connections.

To view network connections:
```bash
nmcli connection show
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
After=network-online.target NetworkManager.service
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/path/to/vscode-socks5-namespace/linux/Manjaro/connect.sh
ExecStop=/path/to/vscode-socks5-namespace/linux/Manjaro/disconnect.sh
StandardInput=tty-force

[Install]
WantedBy=multi-user.target
```

Enable:
```bash
sudo systemctl daemon-reload
sudo systemctl enable vscode-vpn-proxy.service
```

## Troubleshooting

### Issue: "dante: package not found"

**Solution:** Dante might be named differently in repos:
```bash
# Search for dante
pacman -Ss dante

# Install from AUR if needed
yay -S dante
```

### Issue: Pamac asking for password repeatedly

This is normal behavior for GUI package installation. The script uses command-line installation to avoid this.

### Issue: "Module 'tun' not found"

**Solution:** Load the TUN module:
```bash
sudo modprobe tun
echo "tun" | sudo tee -a /etc/modules-load.d/tun.conf
```

### Issue: Network interface not detected

**Solution:** List interfaces with Manjaro's network tools:
```bash
# Command line
ip link show

# GUI
nmcli device status

# Or use Manjaro Settings Manager
manjaro-settings-manager
```

### Issue: UFW blocking connections

```bash
# Check UFW rules
sudo ufw status verbose

# Allow namespace traffic
sudo ufw allow from 10.200.200.0/24

# Check iptables rules
sudo iptables -L -n -v
```

### Issue: Conflicts with existing VPN connection

This script creates an isolated namespace and should NOT conflict with:
- NetworkManager VPN connections
- OpenVPN connections running on the host
- WireGuard connections

Each connection runs in its own isolated space.

## Advanced Configuration

### Using with Manjaro Hello

Manjaro Hello is the welcome screen. You can create a custom application entry:

```bash
# Create desktop entry
nano ~/.local/share/applications/vscode-vpn.desktop
```

Add:
```ini
[Desktop Entry]
Type=Application
Name=VSCode with VPN
Comment=Launch VSCode through isolated VPN namespace
Exec=/path/to/vscode-socks5-namespace/linux/Manjaro/connect.sh
Icon=vscode
Terminal=true
Categories=Development;Network;
```

### Kernel Parameters

For better network performance, consider these kernel parameters:

```bash
sudo nano /etc/sysctl.d/99-vpn-namespace.conf
```

Add:
```ini
# Better namespace performance
net.ipv4.ip_forward = 1
net.ipv4.conf.all.rp_filter = 0
net.ipv4.conf.default.rp_filter = 0
```

Apply:
```bash
sudo sysctl --system
```

### Using Different Kernels

Manjaro allows easy kernel switching. The script works with:
- linux (mainline kernel)
- linux-lts (long-term support)
- linux-rt (realtime kernel)
- linux-zen (optimized kernel)

To switch kernels, use Manjaro Settings Manager:
```bash
sudo manjaro-settings-manager
# Go to "Kernel" section
```

## Compatibility

This script is compatible with:
- Manjaro Linux (all recent versions)
- All Manjaro desktop environments (KDE, XFCE, GNOME, i3, etc.)
- Both stable and testing branches

## Support

For Manjaro-specific issues:
- [Manjaro Forums](https://forum.manjaro.org/)
- [Manjaro Wiki](https://wiki.manjaro.org/)
- [Manjaro Telegram](https://t.me/manjarolinux)
- [Arch Wiki](https://wiki.archlinux.org/) (most Arch documentation applies to Manjaro)

## Notes for Users Migrating from the Original Script

If you were using the original hardcoded script:

1. **Configuration is now interactive** - No need to edit variables manually
2. **Auto-detection** - Network interface and IP are automatically detected
3. **Better error handling** - Clear messages if something goes wrong
4. **Automatic package installation** - Script offers to install missing packages
5. **Saved configuration** - Your settings are saved for easy disconnection

The functionality remains exactly the same, just with better user experience!
