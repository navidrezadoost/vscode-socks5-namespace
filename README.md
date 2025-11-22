# VSCode & JetBrains SOCKS5 VPN Namespace

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS%20%7C%20Windows-blue)]()
[![Version](https://img.shields.io/badge/Version-2.0.0-green.svg)]()

**Isolated OpenVPN connection for VSCode & JetBrains IDEs - Keep your host IP while your IDEs use VPN**

## 🌟 Overview

This project provides scripts to create an isolated network environment where **only your IDEs** (VSCode, IntelliJ IDEA, PyCharm, WebStorm, DataGrip, etc.) use a VPN connection, while the rest of your system maintains its original IP address.

### Why This Matters

In countries with internet filtering or restrictive networks:
- **Developers** need VPN to access IDE extensions, plugins, GitHub, and development resources
- **BUT** turning on system-wide VPN prevents:
  - Colleagues from accessing your local development servers
  - Testing applications on local network
  - Accessing local network resources
  - Using your real IP for legitimate purposes

### The Solution

This project creates an **isolated network namespace** (on Linux) or equivalent isolation (macOS/Windows) that:
- ✅ Routes **only IDE traffic** through VPN (VSCode, JetBrains IDEs)
- ✅ Keeps your **host IP unchanged** for all other applications
- ✅ Allows **local network access** for colleagues and testing
- ✅ Provides **true traffic isolation**

### 🎯 Supported IDEs

#### ✅ Fully Tested & Supported
- **VSCode** - Visual Studio Code
- **IntelliJ IDEA** - Ultimate & Community
- **PyCharm** - Professional & Community
- **WebStorm** - JavaScript & TypeScript IDE
- **DataGrip** - Database IDE
- **PhpStorm** - PHP IDE
- **GoLand** - Go IDE
- **CLion** - C/C++ IDE
- **Rider** - .NET IDE
- **RubyMine** - Ruby IDE
- **AppCode** - iOS/macOS IDE
- **Android Studio** - Built on IntelliJ platform

## 🚀 Quick Start

### Choose Your Platform

<table>
<tr>
<td width="33%" align="center">

**🐧 Linux**

[Arch](linux/Arch) • [Ubuntu](linux/Ubuntu) • [Fedora](linux/Fedora)  
[Manjaro](linux/Manjaro) • [openSUSE](linux/openSUSE) • [Kali](linux/Kali)  
[Mint](linux/Mint) • [Pop!_OS](linux/Pop!_OS) • [RHEL](linux/RHEL)  
[Zorin](linux/Zorin%20OS) • [Parrot](linux/Parrot%20OS)

```bash
cd linux/<your-distro>
chmod +x connect.sh
./connect.sh
```


</td>
<td width="33%" align="center">

**🍎 macOS**

[View Instructions](mac)

```bash
cd mac
chmod +x connect.sh
./connect.sh
```

⚠️ Limited isolation  
(no namespace support)

</td>
<td width="33%" align="center">

**🪟 Windows**

[View Instructions](windows)

```powershell
cd windows
.\connect.ps1
```

Requires WSL2

</td>
</tr>
</table>

## 📋 How It Works

### Linux (Full Isolation)

```
┌─────────────────────────────────────────────────┐
│                  Your Computer                  │
├─────────────────────────────────────────────────┤
│                                                 │
│  🌐 Host Network (Real IP: 192.168.1.100)     │
│  ├─ Browser: Uses real IP ✓                    │
│  ├─ Other apps: Use real IP ✓                  │
│  └─ Local servers: Accessible to team ✓        │
│                                                 │
│  ╔═══════════════════════════════════════╗     │
│  ║  🔒 VPN Namespace (Isolated)          ║     │
│  ║  ├─ OpenVPN: VPN IP (5.6.7.8)         ║     │
│  ║  ├─ SOCKS5 Proxy                      ║     │
│  ║  └─ VSCode: Uses VPN IP ✓             ║     │
│  ╚═══════════════════════════════════════╝     │
│                                                 │
└─────────────────────────────────────────────────┘
```

### Windows/WSL2

Uses WSL2 to provide the same Linux namespace isolation, with port forwarding to Windows.

### macOS

Limited isolation using routing and SOCKS proxy (no native namespace support).

## 🎯 Features

- **✨ Interactive Setup** - No manual configuration editing required
- **🎨 Multi-IDE Support** - Works with VSCode and all JetBrains IDEs
- **🔍 Auto-Detection** - Automatically detects network interface and IP
- **📦 Dependency Management** - Offers to install missing packages
- **🎨 Colored Output** - Clear, beautiful terminal interface
- **💾 Configuration Saving** - Saves setup for easy disconnect
- **🧪 Built-in Testing** - Verifies proxy functionality including JetBrains plugins
- **🔄 Easy Disconnect** - Clean teardown of all resources
- **📚 Comprehensive Docs** - Platform-specific guides for each OS and IDE

## 📖 Documentation

### Getting Started

- **[QUICKSTART.md](QUICKSTART.md)** - Fast setup guide for all platforms
- **[USAGE_GUIDE.md](USAGE_GUIDE.md)** - How to configure VSCode, JetBrains IDEs, browsers, and more
- **[JETBRAINS_GUIDE.md](JETBRAINS_GUIDE.md)** - 📘 Comprehensive JetBrains IDEs configuration guide
- **[TESTING.md](TESTING.md)** - Comprehensive testing procedures
- **[CHANGELOG.md](CHANGELOG.md)** - Version history and changes

### Platform-Specific Guides

- **Linux Distributions:**
  - [Arch Linux](linux/Arch/README.md)
  - [Ubuntu / Debian](linux/Ubuntu/README.md)
  - [Fedora / RHEL / CentOS](linux/Fedora/README.md)
  - [Manjaro](linux/Manjaro/README.md)
  - [openSUSE](linux/openSUSE/README.md)
  - [Kali Linux](linux/Kali/README.md)
  - [Parrot OS](linux/Parrot%20OS/README.md)

- **Other Platforms:**
  - [macOS](mac/README.md)
  - [Windows (WSL2)](windows/README.md)

### Additional Resources

- **[SECURITY.md](SECURITY.md)** - Security best practices and hardening
- **[CONTRIBUTING.md](CONTRIBUTING.md)** - How to contribute
- **[PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)** - Technical architecture overview

## 🛠️ Requirements

### All Platforms
- **OpenVPN configuration file (.ovpn)** - See [Preparing Your OpenVPN Config](#-preparing-your-openvpn-config) below
- Root/Administrator privileges

### Linux
- `openvpn` - VPN client
- `dante-server` (or `dante`) - SOCKS5 server
- `socat` - Socket relay
- `curl` - HTTP client
- `iproute2` - Network namespaces
- `iptables` - Firewall rules

### macOS
- Homebrew package manager
- Same packages as Linux (installed via brew)

### Windows
- Windows 10 version 2004+ or Windows 11
- WSL2 (Windows Subsystem for Linux 2)
- Ubuntu or another Linux distribution in WSL2

## 📋 Preparing Your OpenVPN Config

Before running the scripts, you need an OpenVPN configuration file (`.ovpn`).

### Where to Get Your .ovpn File

1. **VPN Provider:** Download from your VPN service (NordVPN, ProtonVPN, ExpressVPN, etc.)
2. **Corporate VPN:** Request from your IT department
3. **Self-hosted:** Export from your OpenVPN server

### Setting Up Your Config File

**1. Save your .ovpn file in an accessible location:**

```bash
# Create a VPN directory
mkdir -p ~/vpn

# Move your downloaded config there
mv ~/Downloads/your-vpn.ovpn ~/vpn/config.ovpn

# Secure the file
chmod 600 ~/vpn/config.ovpn
```

**2. When the script asks for the path, provide the FULL absolute path:**

```
Enter full path to your OpenVPN config file: /home/yourusername/vpn/config.ovpn
```

**Important:**
- Use **absolute paths** (e.g., `/home/user/vpn/config.ovpn`)
- Don't use `~` (may not expand with sudo)
- Common locations: `/etc/openvpn/`, `~/vpn/`, `~/Documents/vpn/`

**3. (Optional) Add credentials for automatic login:**

If your VPN requires username/password:

```bash
# Create credentials file
cat > ~/vpn/credentials.txt <<EOF
your_username
your_password
EOF

# Secure it
chmod 600 ~/vpn/credentials.txt

# Add to your .ovpn file
echo "auth-user-pass /home/yourusername/vpn/credentials.txt" >> ~/vpn/config.ovpn
```

**4. Test your config before using the script:**

```bash
# Test connection
sudo openvpn --config ~/vpn/config.ovpn

# If it connects successfully, press Ctrl+C
# You're now ready to use it with this script!
```

## 🎬 Usage Example

### Connect

```bash
$ cd linux/Ubuntu
$ ./connect.sh

╔══════════════════════════════════════════════════════════╗
║  VSCode SOCKS5 VPN Namespace Setup                      ║
║  Isolated OpenVPN connection for VSCode                 ║
╚══════════════════════════════════════════════════════════╝

✓ All dependencies found

Configuration Setup
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Enter namespace name [vpnspace]: 
Enter full path to your OpenVPN config file: /home/user/vpn/config.ovpn
Enter your main network interface [eth0]: 
Enter your host IP address [192.168.1.100]: 
Enter SOCKS5 port inside namespace [1080]: 
Enter local proxy port (exposed to host) [1081]: 
Enter DNS server for namespace [8.8.8.8]: 
Launch VSCode with proxy after setup? (y/n) [y]: 

✓ VPN connected successfully! Assigned IP: 10.8.0.2
✓ Proxy working inside namespace! Public IP: 5.6.7.8
✓ Proxy successfully accessible from host!

╔══════════════════════════════════════════════════════════╗
║              Setup Completed Successfully!               ║
╚══════════════════════════════════════════════════════════╝

Proxy address: socks5://10.200.200.2:1081
VPN public IP: 5.6.7.8

✓ VSCode launched
```

### Using the SOCKS5 Proxy

Once connected, you can configure various applications to use the proxy:

**VSCode:**
```bash
code --proxy-server="socks5://10.200.200.2:1081"
```

**JetBrains IDEs (IntelliJ, PyCharm, WebStorm, etc.):**
- Go to: `Settings` → `Appearance & Behavior` → `System Settings` → `HTTP Proxy`
- Select: `Manual proxy configuration` → `SOCKS`
- Host: `10.200.200.2`, Port: `1081`

**Git:**
```bash
git config --global http.proxy socks5://10.200.200.2:1081
```

**cURL:**
```bash
curl --socks5-hostname 10.200.200.2:1081 https://api.github.com
```

**📖 For complete configuration guides, see [USAGE_GUIDE.md](USAGE_GUIDE.md)**

This guide includes detailed instructions for:
- Visual Studio Code (4 methods)
- All JetBrains IDEs (IntelliJ, PyCharm, WebStorm, etc.)
- Web Browsers (Firefox, Chrome, Brave)
- Git (HTTPS and SSH)
- Docker
- Terminal applications (curl, wget, ssh)
- And many more...

### Disconnect

```bash
$ ./disconnect.sh

✓ Processes terminated
✓ Namespace removed
✓ Virtual interfaces removed
✓ iptables rules removed
✓ Temporary files cleaned
✓ All resources successfully cleaned

System is now clean. You can safely re-run the connect script anytime.
```

## 🔧 Troubleshooting

### Common Issues

#### "Permission Denied"
**Solution:** Run with sudo or ensure your user is in the correct group:
```bash
# Linux
sudo usermod -aG wheel $USER  # Arch/Fedora
sudo usermod -aG sudo $USER   # Ubuntu/Debian
```

#### "dante-server not found"
**Solution:** Package name varies by distribution:
- Ubuntu/Debian: `dante-server`
- Arch/Manjaro: `dante`
- Fedora/RHEL: `dante-server` (requires EPEL)

#### "VPN connection failed"
**Solution:** Check OpenVPN logs:
```bash
cat /tmp/openvpn_<namespace>.log
```

#### DNS not working
**Solution:** Try different DNS servers when prompted (1.1.1.1, 9.9.9.9)

### Platform-Specific Issues

See the README.md file in each platform directory for detailed troubleshooting.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Areas for Contribution
- Support for additional Linux distributions
- Improved error handling
- Additional features
- Documentation improvements
- Bug fixes

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Original concept developed for developers in countries with internet filtering
- Inspired by the need for isolated VPN connections during development
- Built with love for the open-source community

## 💡 Use Cases

### Development in Restricted Countries
- Access VSCode extensions marketplace through VPN
- Access GitHub and development resources
- Keep local IP for team collaboration
- Test local applications without VPN interference

### Penetration Testing (Kali/Parrot)
- Separate development (VSCode) traffic from pentesting traffic
- Different VPN connections for different activities
- Maintain multiple isolated connections

### Privacy-Conscious Development
- Route sensitive development traffic through VPN
- Keep regular browsing on normal connection
- Separate work and personal traffic

### Multi-VPN Scenarios
- Run multiple VPN connections simultaneously
- Each in its own isolated namespace
- No conflicts between connections

## 📞 Support

- **Issues:** [GitHub Issues](https://github.com/navidrezadoost/dev-socks-isolation/issues)
- **Discussions:** [GitHub Discussions](https://github.com/navidrezadoost/dev-socks-isolation/discussions)

## 🌐 Tested Platforms

### Linux (Full Support - Network Namespace Isolation)
- ✅ Arch Linux
- ✅ Manjaro
- ✅ Ubuntu (20.04, 22.04, 24.04)
- ✅ Linux Mint
- ✅ Pop!_OS
- ✅ Zorin OS
- ✅ Fedora (37+)
- ✅ RHEL (8, 9)
- ✅ CentOS Stream
- ✅ Rocky Linux
- ✅ AlmaLinux
- ✅ openSUSE Leap
- ✅ openSUSE Tumbleweed
- ✅ Kali Linux
- ✅ Parrot Security OS

### macOS (Limited Support - SOCKS Proxy Only)
- ⚠️ macOS Big Sur (11.x) and newer

### Windows (Full Support via WSL2)
- ✅ Windows 10 (version 2004+)
- ✅ Windows 11

## 🔒 Security

This tool is designed for legitimate development purposes. Always ensure:
- You have the right to use VPN services in your location
- Your VPN provider allows this type of connection
- You're complying with your organization's network policies
- Your OpenVPN credentials are stored securely

---

<p align="center">
Made with ❤️ for developers facing internet restrictions
</p>

<p align="center">
<a href="#vscode-socks5-vpn-namespace">Back to Top</a>
</p>
