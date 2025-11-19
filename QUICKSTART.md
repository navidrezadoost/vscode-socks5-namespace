# Quick Start Guide

## ⚠️ Before You Start

### Get Your OpenVPN Config File Ready

You need a `.ovpn` configuration file from your VPN provider. 

**Quick setup:**
```bash
# 1. Create a directory for your VPN config
mkdir -p ~/vpn

# 2. Move/copy your downloaded .ovpn file there
cp ~/Downloads/your-vpn.ovpn ~/vpn/config.ovpn

# 3. Secure the file
chmod 600 ~/vpn/config.ovpn

# 4. Remember the full path - you'll need it!
# Example: /home/yourusername/vpn/config.ovpn
```

**Don't have a .ovpn file?**
- Download from your VPN provider (NordVPN, ProtonVPN, ExpressVPN, etc.)
- Or request from your IT department (corporate VPN)

---

## Choose Your Platform and Follow the Steps

### 🐧 Linux

**1. Navigate to your distribution folder:**
```bash
cd linux/<YourDistro>
# Examples:
# cd linux/Ubuntu
# cd linux/Arch
# cd linux/Fedora
# cd linux/Manjaro
```

**2. Run the connect script:**
```bash
chmod +x connect.sh
./connect.sh
```

**3. Follow the interactive prompts:**
- **Enter path to your .ovpn file:** `/home/yourusername/vpn/config.ovpn` (use FULL path)
- Confirm auto-detected network settings (or customize)
- Choose SOCKS ports (or use defaults: 1080, 1081)
- Choose DNS server (or use default: 8.8.8.8)
- Choose whether to launch VSCode

**4. Done!** VSCode will launch with VPN proxy, or use:
```bash
code --proxy-server="socks5://10.200.200.2:1081"
```

**5. To disconnect:**
```bash
./disconnect.sh
```

---

### 🍎 macOS

**1. Navigate to mac folder:**
```bash
cd mac
```

**2. Run the connect script:**
```bash
chmod +x connect.sh
./connect.sh
```

**3. Follow the prompts:**
- Enter path to your .ovpn file
- Choose SOCKS port
- Choose DNS server
- Choose whether to launch VSCode

**4. Done!** VSCode will launch with proxy, or use:
```bash
code --proxy-server="socks5://127.0.0.1:1080"
```

**5. To disconnect:**
```bash
./disconnect.sh
```

---

### 🪟 Windows

**1. Open PowerShell as Administrator:**
- Right-click PowerShell
- Select "Run as Administrator"

**2. Navigate to windows folder:**
```powershell
cd windows
```

**3. Set execution policy (first time only):**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**4. Run the connect script:**
```powershell
.\connect.ps1
```

**5. Follow the prompts:**
- Enter path to your .ovpn file (Windows path)
- Choose SOCKS port
- Choose DNS server
- Choose whether to launch VSCode

**6. Done!** VSCode will launch with proxy, or use:
```powershell
code --proxy-server="socks5://127.0.0.1:1080"
```

**7. To disconnect:**
```powershell
.\disconnect.ps1
```

---

## What You Need

### All Platforms
- ✅ OpenVPN configuration file (.ovpn)
- ✅ Admin/sudo privileges
- ✅ Internet connection

### Platform-Specific
- **Linux**: No additional requirements (scripts install dependencies)
- **macOS**: Homebrew (scripts will guide you if not installed)
- **Windows**: WSL2 installed (scripts will guide you if not installed)

---

## First-Time Setup

### Linux
The script will offer to install missing packages automatically.

### macOS
1. Install Homebrew if not installed:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

2. Run the script - it will install dependencies via Homebrew

### Windows
1. Install WSL2:
```powershell
wsl --install
```

2. Restart computer

3. Open Ubuntu from Start menu and complete setup

4. Run the script - it will install dependencies in WSL2

---

## Verification

After running the connect script, verify it's working:

### Check VPN IP
The script shows your VPN IP automatically. Or check manually:

**Linux:**
```bash
curl --socks5-hostname 10.200.200.2:1081 https://api.ipify.org
```

**macOS:**
```bash
curl --socks5-hostname 127.0.0.1:1080 https://api.ipify.org
```

**Windows:**
```powershell
curl.exe --socks5-hostname 127.0.0.1:1080 https://api.ipify.org
```

### Check Host IP (should be unchanged)
```bash
curl https://api.ipify.org
```

Both IPs should be different!

---

## Troubleshooting

### "Permission Denied"
**Solution:** Use sudo (Linux/macOS) or run as Administrator (Windows)

### "Dependencies not found"
**Solution:** Let the script install them automatically when prompted

### "VPN connection failed"
**Solution:** 
1. Check your .ovpn file path is correct
2. Verify your OpenVPN credentials
3. Check the log files mentioned in error messages

### "Cannot reach proxy from host"
**Solution:**
1. Check firewall settings
2. Verify namespace is created: `sudo ip netns list` (Linux)
3. Check if processes are running: `ps aux | grep -E "openvpn|sockd"`

---

## Where to Get Help

1. **Check the README** in your platform folder for detailed docs
2. **Read troubleshooting sections** in platform-specific READMEs
3. **Open an issue** on GitHub with:
   - Your OS and version
   - Error messages
   - Steps you tried
   - Log file contents

---

## After Setup

### Using VSCode
Your VSCode is now using the VPN! 

**Extensions marketplace** ✓  
**GitHub access** ✓  
**All development resources** ✓  

### Your Host
Everything else on your computer uses your real IP:

**Browser** → Real IP  
**Local servers** → Accessible to colleagues  
**Other applications** → Real IP  

### Testing Local Servers
Your colleagues can still access your local servers:
```bash
# Your local server
http://your-real-ip:3000

# This works because host IP is unchanged!
```

---

## Multiple VPN Connections

You can run multiple isolated VPN connections:

1. Run the script again
2. Use a different namespace name (e.g., "vpn2")
3. Use different ports
4. Each connection is completely isolated!

---

## Configuring Other Applications

Besides VSCode, you can configure many other tools to use the SOCKS5 proxy:

### JetBrains IDEs (IntelliJ, PyCharm, WebStorm, etc.)

1. Go to: `Settings` → `Appearance & Behavior` → `System Settings` → `HTTP Proxy`
2. Select: `Manual proxy configuration` → `SOCKS`
3. Host: `10.200.200.2`, Port: `1081`

### Web Browsers

**Firefox:**
- `Settings` → `Network Settings` → Manual proxy → SOCKS v5
- Host: `10.200.200.2`, Port: `1081`

**Chrome:**
```bash
google-chrome --proxy-server="socks5://10.200.200.2:1081"
```

### Git

```bash
git config --global http.proxy socks5://10.200.200.2:1081
```

### Terminal (curl, wget, etc.)

```bash
export ALL_PROXY=socks5://10.200.200.2:1081
```

**📖 For complete configuration guides and more applications, see [USAGE_GUIDE.md](USAGE_GUIDE.md)**

The usage guide includes detailed instructions for:
- Visual Studio Code (4 different methods)
- All JetBrains IDEs
- Web browsers (Firefox, Chrome, Brave, etc.)
- Git (both HTTPS and SSH)
- Docker
- Slack, Discord, Postman, and more
- System-wide proxy configuration

---

## Security Note

🔒 This tool is for **legitimate development purposes**.

- Ensure you have the right to use VPN in your location
- Comply with your organization's network policies
- Keep your .ovpn credentials secure
- Use strong passwords

---

## What's Next?

1. ✅ Set up your VPN namespace
2. ✅ Launch VSCode with proxy
3. ✅ Access development resources through VPN
4. ✅ Keep local network for collaboration
5. 🎉 Enjoy productive development!

---

## Additional Documentation

- **[USAGE_GUIDE.md](USAGE_GUIDE.md)** - Complete guide for configuring applications
- **[README.md](README.md)** - Full project documentation
- **[TESTING.md](TESTING.md)** - Testing and verification procedures
- **[SECURITY.md](SECURITY.md)** - Security best practices
- **Platform-specific READMEs** - In each distribution folder
