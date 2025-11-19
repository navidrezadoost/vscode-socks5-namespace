# VSCode SOCKS5 VPN Proxy - macOS

## Important Notice

⚠️ **macOS Limitation**: Unlike Linux, macOS does not support network namespaces. This means true traffic isolation (where only VSCode uses VPN while other apps use your real IP) is not possible on macOS.

This script provides:
- OpenVPN connection
- SOCKS5 proxy on the VPN interface
- VSCode configured to use the SOCKS5 proxy

However, note that:
- Other applications can also use the VPN connection if configured
- True isolation requires using a VM or container

## Prerequisites

- **Homebrew** - macOS package manager
- `openvpn` - OpenVPN client
- `dante` - SOCKS5 server
- `socat` - Socket relay  
- `curl` - HTTP client (pre-installed on macOS)

## Quick Installation

### Install Homebrew (if not installed)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Install Dependencies

```bash
brew install openvpn dante socat
```

## Usage

### Connect to VPN

```bash
cd /path/to/vscode-socks5-namespace/mac
chmod +x connect.sh
./connect.sh
```

The script will prompt you for:
- Path to your OpenVPN config file (.ovpn)
- SOCKS5 port (default: 1080)
- DNS server (default: 8.8.8.8)
- Whether to launch VSCode automatically

### Disconnect from VPN

```bash
./disconnect.sh
```

## macOS-Specific Notes

### System Permissions

macOS may ask for permissions when running OpenVPN:
1. Allow OpenVPN to create network interfaces
2. Allow OpenVPN to modify network settings
3. Enter your password when prompted by sudo

### TUN/TAP Driver

Modern versions of macOS include TUN/TAP support for OpenVPN. If you encounter issues:

```bash
# Check if utun interfaces can be created
ifconfig | grep utun
```

### Using with macOS VPN Settings

This script is separate from macOS's built-in VPN settings. You can have both:
- System VPN connection (in System Preferences)
- This script's isolated OpenVPN connection

They won't conflict.

### Alternative Solutions for True Isolation

Since macOS doesn't support network namespaces, consider these alternatives:

#### Option 1: Use Docker

```bash
# Run VSCode in a Docker container with VPN
# This provides true isolation
```

#### Option 2: Use a Linux VM

```bash
# Install Parallels/VMware/VirtualBox
# Run Linux VM with the Linux version of this script
# Provides true namespace isolation
```

#### Option 3: Use macOS's Built-in VPN with Split Tunneling

Some VPN providers support split tunneling on macOS, allowing you to route only specific apps through VPN.

### Launch Agents (Auto-start on Login)

To auto-start the VPN on login, create a Launch Agent:

```bash
mkdir -p ~/Library/LaunchAgents
nano ~/Library/LaunchAgents/com.vscode.vpnproxy.plist
```

Add:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.vscode.vpnproxy</string>
    <key>ProgramArguments</key>
    <array>
        <string>/path/to/vscode-socks5-namespace/mac/connect.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/vpnproxy.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/vpnproxy.error.log</string>
</dict>
</plist>
```

Load it:
```bash
launchctl load ~/Library/LaunchAgents/com.vscode.vpnproxy.plist
```

### Firewall Configuration

If you're using macOS Firewall (System Preferences > Security & Privacy > Firewall):

1. Go to Firewall Options
2. Add OpenVPN to allowed applications
3. Add Dante (sockd) to allowed applications

### Network Locations

macOS supports multiple network locations. You can create separate locations for:
- VPN work
- Regular work
- Home network

Switch between them in: System Preferences > Network > Location

## Troubleshooting

### Issue: "openvpn: command not found"

**Solution:** Ensure Homebrew's bin directory is in your PATH:
```bash
# For Intel Macs
echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.zshrc

# For Apple Silicon Macs
echo 'export PATH="/opt/homebrew/bin:$PATH"' >> ~/.zshrc

# Reload shell
source ~/.zshrc
```

### Issue: Permission denied when starting OpenVPN

**Solution:** OpenVPN needs root privileges:
```bash
# The script uses sudo, but ensure you're in the admin group
dscl . -read /Groups/admin GroupMembership
```

### Issue: "utun interface not created"

**Solution:** Check if another VPN is using the utun interfaces:
```bash
# List all network interfaces
ifconfig | grep utun

# Kill other VPN processes if needed
sudo pkill -f openvpn
```

### Issue: Dante not starting

**Check Dante logs:**
```bash
cat /tmp/danted_macos.log
```

**Common fix:**
```bash
# Reinstall Dante
brew reinstall dante

# Check if sockd binary exists
which sockd
```

### Issue: "Unable to load tun kernel extension"

**Solution (for older macOS versions):**
```bash
# Install TUN/TAP driver
brew install --cask tuntap
```

Note: Newer macOS versions (Big Sur+) have built-in TUN support.

### Issue: DNS not working

**Solution:** macOS DNS can be quirky. Force flush DNS cache:
```bash
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
```

### Issue: Network not working after disconnect

**Solution:** Reset network settings:
```bash
# Renew DHCP lease
sudo ipconfig set en0 DHCP

# Or restart network interface
sudo ifconfig en0 down
sudo ifconfig en0 up
```

## Advanced Configuration

### Using with Tunnelblick

If you prefer GUI management, you can use Tunnelblick:
1. Install Tunnelblick
2. Import your .ovpn file
3. Connect via Tunnelblick
4. Run this script WITHOUT the OpenVPN part (modify script to skip OpenVPN start)

### Custom DNS Servers for Privacy

```bash
# When prompted for DNS, use privacy-focused servers:
# Cloudflare: 1.1.1.1
# Quad9: 9.9.9.9
# Google: 8.8.8.8
```

### Using with Little Snitch

Little Snitch (network monitor) works with this setup:
1. Allow OpenVPN connections
2. Allow Dante (sockd) to listen on localhost
3. Allow VSCode to connect to localhost:1080

## Performance Considerations

### Network Speed

VPN may reduce network speed. To check:
```bash
# Test without VPN
curl -o /dev/null https://speed.cloudflare.com/__down?bytes=100000000

# Test with VPN (through SOCKS proxy)
curl --socks5 127.0.0.1:1080 -o /dev/null https://speed.cloudflare.com/__down?bytes=100000000
```

### CPU Usage

Monitor OpenVPN CPU usage:
```bash
top -pid $(pgrep openvpn)
```

## Security Notes

### Keychain Access

OpenVPN may store credentials in macOS Keychain. Check:
```bash
# Open Keychain Access app
# Look for OpenVPN entries
```

### File Permissions

Ensure your .ovpn file is not world-readable:
```bash
chmod 600 /path/to/your/config.ovpn
```

## Compatibility

This script is compatible with:
- macOS Big Sur (11.x)
- macOS Monterey (12.x)
- macOS Ventura (13.x)
- macOS Sonoma (14.x)
- macOS Sequoia (15.x)

Works on both:
- Intel Macs
- Apple Silicon (M1/M2/M3) Macs

## Support

For macOS-specific issues:
- [Homebrew Discourse](https://discourse.brew.sh/)
- [OpenVPN Forums](https://forums.openvpn.net/)
- [r/macOS on Reddit](https://www.reddit.com/r/macOS/)

## Alternatives

If this solution doesn't meet your needs:

1. **Use Parallels/VMware** - Run Linux VM with full namespace support
2. **Use Docker Desktop** - Run containers with isolated networking
3. **Use Tailscale** - Modern VPN alternative with better macOS integration
4. **Use WireGuard** - Faster, more modern VPN protocol
