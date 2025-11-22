# VSCode SOCKS5 VPN Proxy - Windows

## Important Notice

⚠️ **Windows Approach**: Windows doesn't have native Linux network namespaces. This solution uses WSL2 (Windows Subsystem for Linux 2) to run the same Linux-based namespace isolation, then forwards the SOCKS5 proxy to Windows.

This provides:
- Full Linux network namespace isolation (in WSL2)
- SOCKS5 proxy accessible from Windows
- Only VSCode traffic routed through VPN
- Windows host IP remains unchanged

## Prerequisites

- **Windows 10 version 2004+** or **Windows 11**
- **WSL2** (Windows Subsystem for Linux 2)
- **Administrator privileges**
- A Linux distribution installed in WSL2 (Ubuntu recommended)

## Quick Installation

### 1. Install WSL2

Open PowerShell as Administrator and run:

```powershell
wsl --install
```

This will:
- Enable WSL2
- Install Ubuntu (default distribution)
- Require a restart

After restart, open Ubuntu from the Start menu and complete the initial setup (create username/password).

### 2. Verify WSL2 Installation

```powershell
wsl --version
wsl --list --verbose
```

Ensure the distribution is running version 2.

### 3. Update WSL2 (if needed)

```powershell
wsl --update
```

## Usage

### Connect to VPN

**Open PowerShell as Administrator:**

```powershell
cd \path\to\dev-socks-isolation\windows
.\connect.ps1
```

The script will:
1. Check WSL2 installation
2. Prompt for configuration (OpenVPN config path, ports, DNS, etc.)
3. Install dependencies in WSL2 (openvpn, dante-server, etc.)
4. Create isolated network namespace in WSL2
5. Set up port forwarding from Windows to WSL2
6. Launch VSCode with the proxy (if requested)

### Disconnect from VPN

**Open PowerShell as Administrator:**

```powershell
.\disconnect.ps1
```

## Windows-Specific Notes

### Administrator Privileges

Both scripts require Administrator privileges to:
- Modify WSL2 network settings
- Configure Windows port forwarding
- Modify firewall rules

### Execution Policy

If you get "script cannot be executed" error:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Firewall Configuration

Windows Firewall may block the SOCKS5 proxy. To allow it:

1. Open Windows Defender Firewall
2. Click "Advanced settings"
3. Create Inbound Rule:
   - Rule Type: Port
   - TCP port: 1080 (or your chosen port)
   - Allow the connection
   - Apply to all profiles
   - Name: "VSCode SOCKS5 Proxy"

Or use PowerShell:
```powershell
New-NetFirewallRule -DisplayName "VSCode SOCKS5 Proxy" -Direction Inbound -LocalPort 1080 -Protocol TCP -Action Allow
```

### WSL2 Networking

WSL2 uses a virtualized network adapter. The scripts automatically:
- Detect WSL2 IP address
- Configure port forwarding from Windows (127.0.0.1) to WSL2
- Handle NAT and routing

### Port Forwarding

Port forwarding is automatically configured using `netsh`:
```powershell
netsh interface portproxy add v4tov4 listenport=1080 listenaddress=127.0.0.1 connectport=1080 connectaddress=<WSL2_IP>
```

View current port forwards:
```powershell
netsh interface portproxy show all
```

## Troubleshooting

### Issue: "WSL2 not found"

**Solution:** Install WSL2:
```powershell
# As Administrator
wsl --install
# Restart computer
```

### Issue: "No distributions found"

**Solution:** Install a distribution:
```powershell
wsl --install -d Ubuntu
```

### Issue: WSL2 IP changes after restart

WSL2's IP address can change after Windows restarts. The script automatically detects the current IP each time you run it.

### Issue: Port forwarding not working

**Check port forwarding:**
```powershell
netsh interface portproxy show all
```

**Reset port forwarding:**
```powershell
netsh interface portproxy reset
# Then run connect script again
```

### Issue: "Access Denied" when running script

**Solution:** Run PowerShell as Administrator:
1. Right-click PowerShell
2. Select "Run as Administrator"

### Issue: Cannot connect to proxy from Windows

**Check Windows Firewall:**
```powershell
# Allow port 1080
New-NetFirewallRule -DisplayName "SOCKS Proxy" -Direction Inbound -LocalPort 1080 -Protocol TCP -Action Allow
```

**Test connectivity to WSL2:**
```powershell
# Get WSL2 IP
wsl hostname -I

# Test connection
Test-NetConnection -ComputerName <WSL2_IP> -Port 1080
```

### Issue: OpenVPN fails to start in WSL2

**Check OpenVPN logs:**
```powershell
wsl cat /tmp/openvpn.log
```

**Common fix - Missing TUN module:**
```powershell
# WSL2 kernel should support TUN
# If not, update WSL2 kernel
wsl --update
```

### Issue: DNS not working in WSL2

**Solution:**
```powershell
wsl sudo bash -c "echo 'nameserver 8.8.8.8' > /etc/resolv.conf"
```

Or create `/etc/wsl.conf` in WSL2:
```ini
[network]
generateResolvConf = false
```

### Issue: VSCode not launching

**Check if code command exists:**
```powershell
Get-Command code
```

**Install VSCode:**
- Download from https://code.visualstudio.com/
- Ensure "Add to PATH" is selected during installation

## Advanced Configuration

### Using Different WSL2 Distributions

To use a specific distribution:

```powershell
# List distributions
wsl --list

# Set default distribution
wsl --set-default <DistroName>

# Run script (it will use the default distribution)
.\connect.ps1
```

### Persistent Port Forwarding

To make port forwarding persist across reboots, create a scheduled task:

```powershell
$action = New-ScheduledTaskAction -Execute "netsh" -Argument "interface portproxy add v4tov4 listenport=1080 listenaddress=127.0.0.1 connectport=1080 connectaddress=<WSL2_IP>"
$trigger = New-ScheduledTaskTrigger -AtStartup
Register-ScheduledTask -TaskName "WSL2 SOCKS Proxy Forward" -Action $action -Trigger $trigger -RunLevel Highest
```

Note: WSL2 IP may change, so this is not fully reliable.

### Using with Windows Terminal

For better experience, use Windows Terminal:
1. Install from Microsoft Store
2. Set default profile to PowerShell
3. Run as Administrator

### Integration with Windows VPN

This setup is separate from Windows built-in VPN. You can have:
- Windows VPN connection (for other apps)
- WSL2 isolated VPN (for VSCode only)

They won't conflict.

### Docker Desktop Compatibility

If you're using Docker Desktop for Windows (which also uses WSL2):
- The scripts are compatible with Docker Desktop
- Both can run simultaneously
- They use separate WSL2 distributions

## Performance Considerations

### WSL2 Overhead

WSL2 adds minimal overhead:
- Network latency: ~1-2ms
- Memory: ~50-100MB for WSL2 instance
- CPU: Negligible when idle

### Optimizing WSL2 Performance

Create `.wslconfig` in your Windows home directory (`C:\Users\<YourName>\.wslconfig`):

```ini
[wsl2]
memory=4GB
processors=2
swap=2GB
```

### Network Speed

Test network speed:
```powershell
# In WSL2
wsl curl -o /dev/null https://speed.cloudflare.com/__down?bytes=100000000
```

## Security Notes

### OpenVPN Credentials

Store OpenVPN credentials securely:
- Use Windows Credential Manager
- Or encrypted config files

### File Permissions in WSL2

Ensure your OpenVPN config is not world-readable:
```powershell
wsl chmod 600 /path/to/config.ovpn
```

### Windows Defender

Windows Defender may scan network traffic. To exclude WSL2:
1. Open Windows Security
2. Virus & threat protection settings
3. Add exclusion for: `C:\Users\<YourName>\AppData\Local\Packages\CanonicalGroupLimited*`

## Alternative Approaches

If WSL2 doesn't work for you:

### Option 1: Native Windows OpenVPN

Use OpenVPN GUI for Windows with manual SOCKS5 setup:
1. Install OpenVPN GUI
2. Install Dante SOCKS server for Windows (limited support)
3. Manually configure routing

### Option 2: Virtual Machine

Run a Linux VM with Hyper-V:
1. Enable Hyper-V
2. Create Ubuntu VM
3. Run Linux version of scripts in VM
4. Forward ports to Windows

### Option 3: Docker

Use Docker Desktop with Linux containers:
```powershell
docker run -it --privileged ubuntu /bin/bash
# Run Linux scripts inside container
```

## Compatibility

This script is compatible with:
- Windows 10 version 2004 and newer
- Windows 11 (all versions)
- WSL2 with any Linux distribution (Ubuntu, Debian, Fedora, etc.)

## Support

For Windows/WSL2-specific issues:
- [WSL Documentation](https://docs.microsoft.com/en-us/windows/wsl/)
- [WSL GitHub Issues](https://github.com/microsoft/WSL/issues)
- [Windows Terminal Documentation](https://docs.microsoft.com/en-us/windows/terminal/)

## FAQ

**Q: Can I use this without WSL2?**  
A: No, WSL2 is required for Linux network namespace support. Consider using a VM as an alternative.

**Q: Will this work with Windows Home edition?**  
A: Yes, WSL2 is available on Windows Home.

**Q: Does this slow down my Windows?**  
A: No, WSL2 uses minimal resources when idle.

**Q: Can I use multiple VPN connections?**  
A: Yes, create different namespaces in WSL2 with different names.

**Q: Is this better than a regular Windows VPN client?**  
A: Yes, because it provides true traffic isolation - only VSCode uses VPN, other apps use your real IP.
