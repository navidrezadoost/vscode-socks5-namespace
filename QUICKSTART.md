# Quick Start Guide

This guide will help you get vscode-vpnspace up and running in 5 minutes.

## Prerequisites

Install required packages:

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install openvpn dante-server netcat-openbsd

# Fedora/RHEL/CentOS
sudo dnf install openvpn dante-server nmap-ncat

# Arch Linux
sudo pacman -S openvpn dante
```

## Step 1: Get Your OpenVPN Config

You need a `.ovpn` configuration file from your VPN provider. Common sources:

- **Commercial VPNs**: Download from your provider's website (NordVPN, ExpressVPN, etc.)
- **Self-hosted**: Export from your OpenVPN server
- **Company VPN**: Get from your IT department

Save it somewhere accessible, for example: `~/vpn/myconfig.ovpn`

## Step 2: Clone and Setup

```bash
# Clone the repository
git clone https://github.com/navidrezadoost/vscode-socks5-namespace.git
cd vscode-socks5-namespace

# Make scripts executable (they should already be, but just in case)
chmod +x *.sh
```

## Step 3: Start the VPN Namespace

```bash
sudo ./start-vpnspace.sh ~/vpn/myconfig.ovpn
```

You should see output like:
```
=== Starting VPN Namespace ===
Cleaning up existing namespace (if any)...
Creating network namespace 'vpnspace'...
Creating virtual ethernet pair...
Configuring SOCKS5 proxy (port 1080)...
Starting SOCKS5 proxy in namespace...
Starting OpenVPN connection in namespace...
Waiting for OpenVPN to establish connection (15 seconds)...
✓ OpenVPN is running (PID: 12345)
✓ SOCKS5 proxy is running on localhost:1080

=== VPN Namespace Started Successfully ===

SOCKS5 proxy available at: localhost:1080
```

## Step 4: Test the Connection

Verify your VPN is working:

```bash
# Check your normal IP
curl https://ifconfig.me

# Check your VPN IP (should be different)
curl --socks5 localhost:1080 https://ifconfig.me
```

Or run the automated test:

```bash
./test-vpnspace.sh
```

## Step 5: Launch VSCode

```bash
./launch-vscode.sh
```

VSCode will start with all traffic routed through the VPN. You can verify this by:

1. Opening VSCode's integrated terminal
2. Running: `curl --socks5 localhost:1080 https://ifconfig.me`
3. Comparing with your host IP

## Step 6: Use with Other Applications

### Firefox
```bash
firefox --proxy-server=socks5://localhost:1080
```

### Chrome/Chromium
```bash
chromium --proxy-server=socks5://localhost:1080
```

### Command-line tools
```bash
# curl
curl --socks5 localhost:1080 https://example.com

# wget  
wget -e use_proxy=yes -e http_proxy=socks5://localhost:1080 https://example.com

# git
git config --global http.proxy socks5://localhost:1080
```

### Any application with environment variables
```bash
export http_proxy=socks5://localhost:1080
export https_proxy=socks5://localhost:1080
your-application
```

## Step 7: Clean Up

When you're done, stop everything:

```bash
sudo ./cleanup-vpnspace.sh
```

This removes the namespace, kills processes, and cleans up all resources.

## Common Issues

### "This script must be run as root"
- Use `sudo` for `start-vpnspace.sh` and `cleanup-vpnspace.sh`
- Regular user is fine for `launch-vscode.sh` and `test-vpnspace.sh`

### "OpenVPN failed to start"
- Check your .ovpn file path is correct
- Verify the config file is valid
- Check logs: `sudo journalctl -xe | grep openvpn`

### "SOCKS5 proxy is not running"
- Make sure you ran `start-vpnspace.sh` first
- Check if the namespace exists: `sudo ip netns list`
- Try cleanup and restart

### VPN IPs are the same as host
- Wait a bit longer - VPN might still be connecting
- Check OpenVPN logs: `sudo journalctl -xe | grep openvpn`
- Verify your VPN config file is correct

### Permission denied errors
- Ensure scripts are executable: `chmod +x *.sh`
- Use sudo where required (start and cleanup scripts)

## Tips

1. **Save your config path**: Create an alias for convenience
   ```bash
   echo "alias vpnspace-start='sudo ./start-vpnspace.sh ~/vpn/myconfig.ovpn'" >> ~/.bashrc
   echo "alias vpnspace-stop='sudo ./cleanup-vpnspace.sh'" >> ~/.bashrc
   ```

2. **Check status**: Use the test script anytime
   ```bash
   ./test-vpnspace.sh
   ```

3. **Multiple VPNs**: You can create copies of the scripts with different namespace names and ports

4. **Debugging**: Check system logs if something goes wrong
   ```bash
   sudo journalctl -xe | grep -E "openvpn|danted"
   ```

## Next Steps

- Read [README.md](README.md) for comprehensive documentation
- Check [ARCHITECTURE.md](ARCHITECTURE.md) to understand how it works
- See [CONTRIBUTING.md](CONTRIBUTING.md) if you want to contribute

## Need Help?

- Review the [Troubleshooting section in README.md](README.md#troubleshooting)
- Check system logs: `sudo journalctl -xe`
- Open an issue on GitHub with details about your problem
