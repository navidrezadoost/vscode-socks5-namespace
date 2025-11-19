# vscode-vpnspace

Run VSCode (or any app) through an **isolated OpenVPN connection** using Linux network namespaces — **without affecting your host traffic**.

## Features

- ✅ **Fully isolated OpenVPN** in a separate network namespace
- ✅ **Dante SOCKS5 proxy** exposed safely to the host
- ✅ **One-click start & full cleanup** scripts
- ✅ **VSCode launched automatically** with the isolated proxy
- ✅ **No root persistence** — everything cleaned on exit
- ✅ **Works with any .ovpn config**

## How It Works

This project uses Linux network namespaces to create an isolated network environment where OpenVPN runs completely separately from your host system. A SOCKS5 proxy (Dante) bridges the gap, allowing applications like VSCode to route traffic through the VPN without affecting other applications on your system.

```
┌─────────────────────────────────────────────────────────┐
│ Host System                                             │
│                                                          │
│  ┌──────────────┐          ┌──────────────────────┐    │
│  │   VSCode     │─────────▶│  SOCKS5 Proxy        │    │
│  │              │          │  (localhost:1080)    │    │
│  └──────────────┘          └──────────┬───────────┘    │
│                                       │                 │
│  ┌─────────────────────────────────────┼──────────────┐│
│  │ Network Namespace "vpnspace"        │              ││
│  │                                     ▼              ││
│  │  ┌──────────────┐        ┌──────────────┐        ││
│  │  │   OpenVPN    │───────▶│  VPN Server  │        ││
│  │  │              │        │              │        ││
│  │  └──────────────┘        └──────────────┘        ││
│  │                                                    ││
│  └────────────────────────────────────────────────────┘│
│                                                          │
└─────────────────────────────────────────────────────────┘
```

## Requirements

- Linux (kernel 3.8+, namespace support required)
- Root/sudo access (only for namespace creation)
- OpenVPN
- Dante SOCKS5 server
- VSCode (optional, can be used with other applications)

### Installation (Ubuntu/Debian)

```bash
sudo apt-get update
sudo apt-get install openvpn dante-server netcat-openbsd
```

### Installation (Fedora/RHEL)

```bash
sudo dnf install openvpn dante-server nmap-ncat
```

## Quick Start

1. **Clone this repository:**
   ```bash
   git clone https://github.com/navidrezadoost/vscode-socks5-namespace.git
   cd vscode-socks5-namespace
   ```

2. **Make scripts executable:**
   ```bash
   chmod +x start-vpnspace.sh cleanup-vpnspace.sh launch-vscode.sh
   ```

3. **Start the isolated VPN namespace:**
   ```bash
   sudo ./start-vpnspace.sh /path/to/your/config.ovpn
   ```

4. **Launch VSCode with the proxy:**
   ```bash
   ./launch-vscode.sh
   ```

5. **When done, clean up everything:**
   ```bash
   sudo ./cleanup-vpnspace.sh
   ```

## Usage

### Starting the VPN Namespace

The `start-vpnspace.sh` script sets up everything:

```bash
sudo ./start-vpnspace.sh <path-to-ovpn-config>
```

This will:
- Create a network namespace called "vpnspace"
- Set up a virtual ethernet pair for host-namespace communication
- Start OpenVPN inside the namespace
- Launch a SOCKS5 proxy on `localhost:1080`

### Launching Applications

#### VSCode
```bash
./launch-vscode.sh
```

#### Any application with SOCKS5 support
```bash
# Using environment variables
export http_proxy=socks5://localhost:1080
export https_proxy=socks5://localhost:1080
your-application
```

#### Command-line tools
```bash
# curl
curl --socks5 localhost:1080 https://ifconfig.me

# wget
wget -e use_proxy=yes -e http_proxy=socks5://localhost:1080 https://example.com

# git
git config --global http.proxy socks5://localhost:1080
```

### Testing the Connection

Verify your IP is different when using the proxy:

```bash
# Your host IP
curl https://ifconfig.me

# IP through the VPN
curl --socks5 localhost:1080 https://ifconfig.me
```

### Cleanup

Always run cleanup when you're done:

```bash
sudo ./cleanup-vpnspace.sh
```

This removes:
- The network namespace
- Virtual ethernet interfaces
- Running OpenVPN and Dante processes
- iptables rules
- Temporary configuration files

## Configuration

### Custom SOCKS5 Port

Edit `start-vpnspace.sh` and change:
```bash
SOCKS_PORT="1080"
```

Also update `launch-vscode.sh` to match.

### Custom Namespace Name

Edit both `start-vpnspace.sh` and `cleanup-vpnspace.sh`:
```bash
NAMESPACE="vpnspace"
```

### Network Configuration

The default network setup:
- Host side: `10.200.200.1/24`
- Namespace side: `10.200.200.2/24`

You can change these in `start-vpnspace.sh` if they conflict with your network.

## Troubleshooting

### OpenVPN won't start

1. Check your OpenVPN config file is correct
2. Look at system logs: `sudo journalctl -xe | grep openvpn`
3. Try running OpenVPN manually in the namespace:
   ```bash
   sudo ip netns exec vpnspace openvpn --config your-config.ovpn
   ```

### SOCKS5 proxy not accessible

1. Verify the proxy is running:
   ```bash
   nc -z localhost 1080 && echo "Proxy is running"
   ```

2. Check Dante logs:
   ```bash
   sudo tail -f /var/log/danted.log
   ```

3. Verify the namespace exists:
   ```bash
   sudo ip netns list
   ```

### VSCode won't connect

1. Make sure the SOCKS proxy is running (see above)
2. Try launching VSCode manually with proxy:
   ```bash
   code --proxy-server=socks5://localhost:1080
   ```

### Permission Denied

Remember that creating namespaces requires root privileges. Always use `sudo` for `start-vpnspace.sh` and `cleanup-vpnspace.sh`.

### Cleanup doesn't remove everything

If cleanup fails, you can manually remove the namespace:
```bash
sudo ip netns delete vpnspace
sudo ip link delete veth_host
sudo pkill -f danted
```

## Security Considerations

- The scripts require root/sudo access to create network namespaces
- No processes run as root after initialization (OpenVPN runs in the namespace)
- The SOCKS5 proxy only listens on localhost (not exposed to network)
- All traffic is isolated within the namespace
- Clean shutdown removes all traces of the configuration

## Advanced Usage

### Running Other Applications

You can run any application through the isolated VPN:

```bash
# Firefox
firefox --proxy-server=socks5://localhost:1080

# Chrome/Chromium
chromium --proxy-server=socks5://localhost:1080

# Any SOCKS5-compatible app
your-app --socks5-proxy localhost:1080
```

### Multiple VPN Namespaces

To run multiple isolated VPNs simultaneously, create copies of the scripts with different:
- Namespace names
- SOCKS5 ports
- Network subnets

### Persistent Configuration

For frequently used VPN configurations, create a wrapper script:

```bash
#!/bin/bash
# my-work-vpn.sh
sudo ./start-vpnspace.sh ~/vpn-configs/work.ovpn
./launch-vscode.sh
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Acknowledgments

- Linux network namespaces for isolation
- OpenVPN for VPN connectivity
- Dante for SOCKS5 proxy functionality

## Related Projects

- [graftcp](https://github.com/hmgle/graftcp) - Transparent proxy for any application
- [proxychains](https://github.com/haad/proxychains) - Force applications through proxy
- [slirp4netns](https://github.com/rootless-containers/slirp4netns) - User-mode networking for namespaces

## Support

If you encounter issues:
1. Check the [Troubleshooting](#troubleshooting) section
2. Review system logs: `sudo journalctl -xe`
3. Open an issue on GitHub with detailed information
