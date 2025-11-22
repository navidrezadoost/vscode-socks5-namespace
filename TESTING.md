# Testing Guide

## Overview

This document provides comprehensive testing procedures for the VSCode SOCKS5 VPN Namespace project. Follow these steps to ensure scripts work correctly on your platform.

## Pre-Testing Checklist

### Requirements Verification

Before testing, ensure you have:

- [ ] **OpenVPN configuration file (.ovpn)** - Valid and tested separately (see below)
- [ ] **Root/sudo access** - Ability to run privileged commands
- [ ] **Internet connection** - Stable network access
- [ ] **Disk space** - At least 500MB free for packages and logs
- [ ] **Backup** - Current network configuration backed up

### Preparing Your OpenVPN Configuration

**IMPORTANT:** The script will ask you for the path to your `.ovpn` file during setup. You need to prepare this file first.

#### Where to Get Your .ovpn File

1. **From Your VPN Provider:**
   - Download from your VPN provider's website
   - Common providers: NordVPN, ExpressVPN, ProtonVPN, Private Internet Access, etc.
   - Usually found in "Downloads" or "Configuration Files" section

2. **File Location:**
   Place your `.ovpn` file in a location you can easily reference:
   
   **Recommended locations:**
   ```bash
   # Home directory
   ~/vpn/config.ovpn
   
   # Documents
   ~/Documents/vpn/my-vpn.ovpn
   
   # System-wide (requires sudo)
   /etc/openvpn/my-vpn.ovpn
   ```

   **Example setup:**
   ```bash
   # Create VPN directory in home
   mkdir -p ~/vpn
   
   # Copy your downloaded .ovpn file there
   cp ~/Downloads/my-vpn-config.ovpn ~/vpn/config.ovpn
   
   # Secure the file (recommended)
   chmod 600 ~/vpn/config.ovpn
   ```

3. **What the Script Will Ask:**
   ```
   Enter full path to your OpenVPN config file: 
   ```
   
   **You enter the FULL path, for example:**
   ```
   /home/yourusername/vpn/config.ovpn
   ```
   
   **Or use absolute path:**
   ```
   /etc/openvpn/w29.ovpn
   ```
   
   **Tips:**
   - Use **absolute paths** (starting with `/`)
   - Don't use `~` (may not expand correctly with sudo)
   - Press Tab for auto-completion
   - The file must exist and be readable

4. **Verify Your .ovpn File:**
   
   Before running the script, test your OpenVPN config separately:
   
   ```bash
   # Test the config file is valid
   sudo openvpn --config ~/vpn/config.ovpn
   
   # If it connects successfully, press Ctrl+C to stop
   # Then you're ready to use it with this script
   ```

5. **Common .ovpn File Locations by Provider:**
   
   - **NordVPN:** `~/Downloads/nordvpn_config.ovpn`
   - **ProtonVPN:** `~/Downloads/protonvpn-config.ovpn`
   - **ExpressVPN:** Usually includes `.ovpn` files in downloaded ZIP
   - **Custom VPN:** Wherever your admin provided it

6. **File Contents Check:**
   
   Your `.ovpn` file should contain:
   ```bash
   # View file contents (first 20 lines)
   head -20 ~/vpn/config.ovpn
   ```
   
   **Should see something like:**
   ```
   client
   dev tun
   proto udp
   remote vpn.server.com 1194
   resolv-retry infinite
   nobind
   persist-key
   persist-tun
   ...
   ```
   
   **May also contain:**
   - Embedded certificates (`<ca>`, `<cert>`, `<key>`)
   - Authentication credentials (`auth-user-pass`)
   - Server addresses

7. **Credentials Handling:**
   
   If your VPN requires username/password:
   
   **Option 1: Enter manually (secure)**
   - Script will prompt during connection
   
   **Option 2: Credentials file (convenient)**
   ```bash
   # Create credentials file
   cat > ~/vpn/credentials.txt <<EOF
   your_username
   your_password
   EOF
   
   # Secure it
   chmod 600 ~/vpn/credentials.txt
   
   # Add to .ovpn file
   echo "auth-user-pass /home/yourusername/vpn/credentials.txt" >> ~/vpn/config.ovpn
   ```

### Backup Your Configuration

```bash
# Linux - Backup network configuration
sudo cp /etc/network/interfaces /etc/network/interfaces.backup 2>/dev/null || true
sudo ip addr show > ~/network-config-backup.txt
sudo ip route show > ~/network-routes-backup.txt
sudo iptables-save > ~/iptables-backup.rules

# Backup OpenVPN config
cp /path/to/your/config.ovpn ~/config.ovpn.backup
```

## Platform-Specific Testing

### Linux Testing

#### 1. Ubuntu/Debian Testing

**Test Environment:**
- Ubuntu 22.04 LTS or newer
- Clean installation preferred
- Internet connection active

**Step 1: Navigate to directory**
```bash
cd /path/to/dev-socks-isolation/linux/Ubuntu
ls -la
# Should see: connect.sh, disconnect.sh, README.md
```

**Step 2: Check permissions**
```bash
ls -l connect.sh disconnect.sh
# Should show: -rwxr-xr-x (executable)

# If not executable:
chmod +x connect.sh disconnect.sh
```

**Step 3: Check dependencies before running**
```bash
# Manual dependency check
dpkg -l | grep -E "openvpn|dante-server|socat|curl|iproute2|iptables"

# Expected output should show these packages or they should be missing
```

**Step 4: Run the connect script**
```bash
./connect.sh
```

**Expected Prompts and Responses:**

```
╔══════════════════════════════════════════════════════════╗
║  VSCode SOCKS5 VPN Namespace Setup                      ║
╚══════════════════════════════════════════════════════════╝

Checking dependencies...
```

**If dependencies are missing:**
```
Missing required packages: dante-server socat
Install them with:
  sudo apt update
  sudo apt install dante-server socat

Install missing packages now? (y/n) [y]: y
```

**Response:** Press `y` and `Enter`

**Expected:** Package installation proceeds
```
✓ Packages installed successfully
```

**Configuration prompts:**

1. **Namespace name:**
   ```
   Enter namespace name [vpnspace]: 
   ```
   **Test:** Press `Enter` (use default) or type `testvpn`

2. **OpenVPN config:**
   ```
   Enter full path to your OpenVPN config file: 
   ```
   **Test:** Enter full path to your prepared .ovpn file
   
   **Examples:**
   ```
   /home/yourusername/vpn/config.ovpn
   /etc/openvpn/w29.ovpn
   /home/yourusername/Documents/my-vpn.ovpn
   ```
   
   **Important:**
   - Use **absolute paths** (start with `/`)
   - Don't use `~/` (won't work with sudo)
   - File must exist and be readable
   - Press Tab for auto-completion
   
   **Error case:** If file doesn't exist:
   ```
   File not found. Please enter a valid path.
   ```
   **Recovery:** Enter correct path

3. **Network interface:**
   ```
   Enter your main network interface [eth0]:
   ```
   **Test:** Press `Enter` (use auto-detected) or verify with `ip link show`

4. **Host IP:**
   ```
   Enter your host IP address [192.168.1.100]:
   ```
   **Test:** Press `Enter` (use auto-detected)

5. **SOCKS ports:**
   ```
   Enter SOCKS5 port inside namespace [1080]:
   Enter local proxy port (exposed to host) [1081]:
   ```
   **Test:** Press `Enter` for defaults

6. **DNS server:**
   ```
   Enter DNS server for namespace [8.8.8.8]:
   ```
   **Test:** Press `Enter` or try `1.1.1.1` (Cloudflare)

7. **Launch VSCode:**
   ```
   Launch VSCode with proxy after setup? (y/n) [y]:
   ```
   **Test:** Type `n` for testing (we'll launch manually later)

**Configuration summary:**
```
Configuration Summary:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Namespace:              testvpn
OpenVPN Config:         /home/user/vpn/config.ovpn
Network Interface:      eth0
Host IP:                192.168.1.100
SOCKS Port (internal):  1080
Local Proxy Port:       1081
DNS Server:             8.8.8.8
Launch VSCode:          n
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Proceed with setup? (y/n) [y]:
```

**Response:** Type `y` and `Enter`

**Setup progress:**
```
[1/14] Cleaning up previous instances...
[2/14] Creating network namespace 'testvpn'...
[3/14] Setting up virtual network interfaces...
[4/14] Configuring IPv4 forwarding and NAT rules...
[5/14] Configuring DNS...
[6/14] Generating SOCKS5 server configuration...
[7/14] Connecting to VPN...
[8/14] Waiting for VPN connection...
.........
✓ VPN connected successfully! Assigned IP: 10.8.0.2
[9/14] Starting SOCKS5 proxy server...
[10/14] Testing proxy from inside namespace...
✓ Proxy working inside namespace! Public IP: 5.6.7.8
[11/14] Creating tunnel to expose proxy to host...
[12/14] Testing proxy from host system...
✓ Proxy successfully accessible from host! Public IP: 5.6.7.8
[13/14] Saving configuration...
```

**Success output:**
```
╔══════════════════════════════════════════════════════════╗
║              Setup Completed Successfully!               ║
╚══════════════════════════════════════════════════════════╝

Proxy Configuration:
  SOCKS5 Address:  socks5://10.200.200.2:1081
  VPN Public IP:   5.6.7.8
  Host IP:         192.168.1.100 (unchanged)

✓ All done!
```

**Step 5: Verification Tests**

**Test 1: Check namespace exists**
```bash
sudo ip netns list
# Expected output: testvpn (or vpnspace)
```

**Test 2: Check processes**
```bash
ps aux | grep -E "openvpn|sockd|socat" | grep -v grep
# Expected: Should show 3 processes running
```

**Test 3: Check network interfaces**
```bash
ip link show | grep veth0
# Expected: veth0 interface should exist

sudo ip netns exec testvpn ip link show | grep tun0
# Expected: tun0 interface should exist in namespace
```

**Test 4: Check iptables rules**
```bash
sudo iptables -L -n | grep 10.200.200
# Expected: Should show forwarding rules for 10.200.200.0/24
```

**Test 5: Test VPN IP from namespace**
```bash
sudo ip netns exec testvpn curl -s https://api.ipify.org
# Expected: Should show VPN IP (e.g., 5.6.7.8)
```

**Test 6: Test VPN IP through SOCKS proxy**
```bash
curl -s --socks5-hostname 10.200.200.2:1081 https://api.ipify.org
# Expected: Should show VPN IP (same as above)
```

**Test 7: Test host IP (unchanged)**
```bash
curl -s https://api.ipify.org
# Expected: Should show your real IP (e.g., 192.168.1.100)
```

**Test 8: DNS resolution test**
```bash
sudo ip netns exec testvpn nslookup google.com
# Expected: Should resolve using VPN's DNS
```

**Test 9: Test SOCKS proxy with curl**
```bash
curl -v --socks5-hostname 10.200.200.2:1081 https://google.com
# Expected: Should connect successfully through proxy
```

**Test 10: Launch VSCode manually**
```bash
code --proxy-server="socks5://10.200.200.2:1081" &
```
**Expected:** VSCode launches and can access extensions

**Step 6: Disconnect test**
```bash
./disconnect.sh
```

**Expected output:**
```
╔══════════════════════════════════════════════════════════╗
║  VSCode SOCKS5 VPN Namespace Disconnect                 ║
╚══════════════════════════════════════════════════════════╝

Loading saved configuration...
✓ Configuration loaded

[1/9] Terminating OpenVPN, Dante, and socat processes...
✓ Processes terminated
[2/9] Deleting network namespace 'testvpn'...
✓ Namespace removed
[3/9] Removing virtual network interfaces...
✓ Virtual interfaces removed
[4/9] Removing iptables forwarding and NAT rules...
✓ iptables rules removed
[5/9] Removing temporary configuration and log files...
✓ Temporary files cleaned
[6/9] Checking IPv4 forwarding...
Disable IPv4 forwarding? (Only if not needed by other services) (y/n) [n]: n
IPv4 forwarding left enabled
[7/9] Checking for VSCode instances using the proxy...
No VSCode instances found using the proxy
[8/9] Verifying cleanup...
✓ All resources successfully cleaned

╔══════════════════════════════════════════════════════════╗
║           Cleanup Completed Successfully!                ║
╚══════════════════════════════════════════════════════════╝

✓ System is now clean. You can safely re-run the connect script anytime.
```

**Step 7: Verification after disconnect**

**Test 1: Namespace should be gone**
```bash
sudo ip netns list
# Expected: No output (or namespace not in list)
```

**Test 2: Processes should be terminated**
```bash
ps aux | grep -E "openvpn|sockd|socat" | grep -v grep
# Expected: No output
```

**Test 3: Virtual interfaces removed**
```bash
ip link show | grep veth0
# Expected: No output
```

**Test 4: Network should work normally**
```bash
curl -s https://api.ipify.org
# Expected: Shows your real IP
```

#### Error Scenarios and Recovery

**Error 1: OpenVPN connection fails**

**Symptom:**
```
Error: VPN connection failed! tun0 interface was not created.
Check OpenVPN logs: /tmp/openvpn_testvpn.log
```

**Diagnosis:**
```bash
sudo cat /tmp/openvpn_testvpn.log
```

**Common causes:**
- Incorrect .ovpn file path
- Invalid credentials
- Network connectivity issues
- Firewall blocking VPN

**Recovery:**
```bash
# Fix the issue, then cleanup
./disconnect.sh

# Try again
./connect.sh
```

**Error 2: Dante proxy fails to start**

**Symptom:**
```
Error: Proxy failed inside namespace
```

**Diagnosis:**
```bash
sudo ip netns exec testvpn cat /tmp/danted_testvpn.log
```

**Common causes:**
- Port already in use
- tun0 interface not ready
- dante-server not installed properly

**Recovery:**
```bash
# Check if port is in use
sudo netstat -tunapl | grep 1080

# Kill conflicting process
sudo kill <PID>

# Retry
./disconnect.sh
./connect.sh
```

**Error 3: Permission denied**

**Symptom:**
```
sudo: command not found
or
permission denied
```

**Recovery:**
```bash
# Add user to sudo group (Ubuntu)
sudo usermod -aG sudo $USER

# Log out and log back in
exit
# Login again

# Or use su
su -c "./connect.sh"
```

**Error 4: DNS not working**

**Symptom:**
```
curl: (6) Could not resolve host
```

**Diagnosis:**
```bash
sudo ip netns exec testvpn cat /etc/netns/testvpn/resolv.conf
# Should show: nameserver 8.8.8.8
```

**Recovery:**
```bash
# Manually set DNS
sudo bash -c 'echo "nameserver 1.1.1.1" > /etc/netns/testvpn/resolv.conf'

# Test again
sudo ip netns exec testvpn nslookup google.com
```

**Error 5: Firewall blocking traffic**

**Symptom:**
```
Proxy not reachable from host
```

**Diagnosis:**
```bash
# Check if UFW is blocking
sudo ufw status

# Check iptables
sudo iptables -L -n -v
```

**Recovery:**
```bash
# Allow traffic from namespace
sudo ufw allow from 10.200.200.0/24

# Or temporarily disable firewall for testing
sudo ufw disable
# Test
# Re-enable
sudo ufw enable
```

#### 2. Arch Linux Testing

**Navigate to Arch directory:**
```bash
cd /path/to/dev-socks-isolation/linux/Arch
./connect.sh
```

**Key differences from Ubuntu:**
- Package manager: `pacman` instead of `apt`
- Dante package: `dante` instead of `dante-server`
- Binary name: `sockd` (same)

**Test installation prompt:**
```
Install missing packages now? (y/n) [y]: y
Installing packages...
sudo pacman -S --needed --noconfirm openvpn dante socat curl
```

**Verify installation:**
```bash
pacman -Q openvpn dante socat
```

**Rest of testing same as Ubuntu**

#### 3. Fedora/RHEL Testing

**Navigate to Fedora directory:**
```bash
cd /path/to/dev-socks-isolation/linux/Fedora
./connect.sh
```

**Key differences:**
- Package manager: `dnf` or `yum`
- SELinux warnings expected
- firewalld integration notes

**SELinux handling test:**
```bash
# Check SELinux status
getenforce
# If Enforcing, script will warn

# Temporarily set to permissive for testing
sudo setenforce 0

# Test script
./connect.sh

# Re-enable SELinux
sudo setenforce 1
```

**firewalld test:**
```bash
# Check if active
sudo systemctl status firewalld

# Add namespace zone
sudo firewall-cmd --permanent --zone=trusted --add-source=10.200.200.0/24
sudo firewall-cmd --reload
```

#### 4. Manjaro Testing

**Special test: AUR support**

```bash
cd /path/to/dev-socks-isolation/linux/Manjaro
./connect.sh
```

**If yay is installed:**
```
Trying with yay (AUR helper) if available...
yay -S --needed --noconfirm dante
```

**Test Pamac GUI integration:**
- Script mentions Pamac availability
- Packages can be installed via GUI alternatively

#### 5. Kali Linux Testing

**Special considerations:**
- Most tools pre-installed
- Security-focused warnings
- Pentesting use case notice

```bash
cd /path/to/dev-socks-isolation/linux/Kali
./connect.sh
```

**Expected additional warning:**
```
═══════════════════════════════════════════════════
  ⚠️  KALI PENTESTING NOTICE  ⚠️
═══════════════════════════════════════════════════

This script creates an isolated VPN namespace for VSCode.
Your pentesting tools running on the host will use your REAL IP.
```

**Test namespace isolation:**
```bash
# From host (should show real IP)
nmap --script-help | head -1
curl https://api.ipify.org

# From namespace (should show VPN IP)
sudo ip netns exec vpnspace curl https://api.ipify.org
```

### macOS Testing

**Navigate to mac directory:**
```bash
cd /path/to/dev-socks-isolation/mac
./connect.sh
```

**Homebrew check:**
```
Checking for Homebrew...
Error: Homebrew not found!
Install Homebrew first: https://brew.sh
```

**If Homebrew missing:**
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

**Test with Homebrew:**
```
Checking macOS dependencies...
Missing required packages: openvpn dante socat

Install them with:
  brew install openvpn dante socat

Install missing packages now? (y/n) [y]: y
```

**macOS-specific tests:**

**Test 1: utun interface creation**
```bash
# After VPN connects
ifconfig | grep utun
# Should show: utun0, utun1, etc.
```

**Test 2: Proxy accessibility**
```bash
curl --socks5-hostname 127.0.0.1:1080 https://api.ipify.org
# Should show VPN IP
```

**Test 3: System VPN non-interference**
- macOS VPN settings should not conflict
- Test with and without system VPN active

**macOS limitations:**
- No true namespace isolation
- All traffic on VPN interface affected
- Document this clearly

### Windows (WSL2) Testing

**Open PowerShell as Administrator:**
```powershell
cd \path\to\dev-socks-isolation\windows
```

**Test execution policy:**
```powershell
Get-ExecutionPolicy
# If Restricted:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Run connect script:**
```powershell
.\connect.ps1
```

**WSL2 checks:**
```
Checking WSL2 installation...
✓ Using WSL distribution: Ubuntu
```

**If WSL2 not installed:**
```
Error: WSL2 is not installed!

To install WSL2:
1. Open PowerShell as Administrator
2. Run: wsl --install
3. Restart your computer
4. Run this script again
```

**Installation test:**
```powershell
wsl --install
# Restart required
```

**After restart:**
```powershell
# Verify WSL2
wsl --version
wsl --list --verbose

# Should show version 2
```

**Test script execution:**
```
[1/6] Copying OpenVPN config to WSL...
[2/6] Installing dependencies in WSL...
[3/6] Creating VPN namespace in WSL...
[4/6] Getting WSL IP address...
✓ WSL IP: 172.18.240.1
[5/6] Setting up port forwarding...
[6/6] Testing proxy from Windows...
✓ Proxy accessible from Windows! Public IP: 5.6.7.8
```

**Windows-specific tests:**

**Test 1: Port forwarding**
```powershell
netsh interface portproxy show all
# Should show: 127.0.0.1:1080 -> WSL_IP:1080
```

**Test 2: Firewall rule**
```powershell
Get-NetFirewallRule | Where-Object {$_.DisplayName -like "*SOCKS*"}
```

**Test 3: Proxy from Windows**
```powershell
curl.exe --socks5-hostname 127.0.0.1:1080 https://api.ipify.org
```

**Test 4: WSL namespace**
```powershell
wsl sudo ip netns list
# Should show: vpnspace
```

## Common Testing Scenarios

### Scenario 1: First-Time User (No Dependencies)

**Test:** Run script on fresh system

**Expected behavior:**
1. Script detects missing packages
2. Offers to install them
3. User confirms
4. Installation succeeds
5. Setup continues automatically

**Verification:**
- All dependencies installed
- Script completes successfully
- User doesn't need technical knowledge

### Scenario 2: Existing VPN Connection

**Test:** Run script while another VPN is active

**Setup:**
```bash
# Connect to VPN normally
sudo openvpn --config other-vpn.ovpn --daemon
```

**Run script:**
```bash
./connect.sh
```

**Expected:**
- Script creates separate namespace
- No conflict with existing VPN
- Both VPNs run simultaneously
- Different IPs for each

**Verification:**
```bash
# Host VPN IP
curl https://api.ipify.org

# Namespace VPN IP
curl --socks5-hostname 10.200.200.2:1081 https://api.ipify.org

# Should be different
```

### Scenario 3: Multiple Namespaces

**Test:** Create multiple isolated VPN connections

**Run 1:**
```bash
./connect.sh
# Enter namespace name: vpn1
# Enter local port: 1081
```

**Run 2:**
```bash
./connect.sh
# Enter namespace name: vpn2
# Enter local port: 1082
```

**Expected:**
- Two separate namespaces created
- Two separate SOCKS proxies
- No conflict between them

**Verification:**
```bash
sudo ip netns list
# Should show: vpn1, vpn2

curl --socks5-hostname 10.200.200.2:1081 https://api.ipify.org
curl --socks5-hostname 10.200.200.2:1082 https://api.ipify.org
# May show different IPs if different VPN configs
```

### Scenario 4: Network Interruption

**Test:** Simulate network disconnection during setup

**Setup:**
```bash
./connect.sh
# During "Waiting for VPN connection..." phase:
# Disconnect network cable or disable WiFi
```

**Expected:**
- Script times out after 30 seconds
- Error message displayed
- Cleanup occurs automatically

**Verification:**
```bash
sudo ip netns list
# Should show namespace (requires manual cleanup)

./disconnect.sh
# Should clean up properly
```

### Scenario 5: Invalid OpenVPN Config

**Test:** Use invalid .ovpn file

**Create test file:**
```bash
echo "invalid config" > /tmp/bad.ovpn
```

**Run script:**
```bash
./connect.sh
# Enter path: /tmp/bad.ovpn
```

**Expected:**
- OpenVPN fails to connect
- Error logged to /tmp/openvpn_*.log
- Clear error message to user
- Instructions to check logs

**Recovery:**
```bash
./disconnect.sh
# Use valid config
./connect.sh
```

### Scenario 6: Port Conflict

**Test:** Port already in use

**Setup:**
```bash
# Start something on port 1080
python3 -m http.server 1080 &
```

**Run script:**
```bash
./connect.sh
# Use default port 1080
```

**Expected:**
- Dante fails to bind to port
- Error message about port conflict
- Suggestion to use different port

**Recovery:**
```bash
# Kill conflicting process
pkill -f "http.server 1080"

# Or use different port
./connect.sh
# Enter port: 1082
```

## Performance Testing

### Bandwidth Test

**Test download speed through VPN:**
```bash
# Without VPN
curl -o /dev/null https://speed.cloudflare.com/__down?bytes=100000000

# With VPN proxy
curl --socks5-hostname 10.200.200.2:1081 -o /dev/null https://speed.cloudflare.com/__down?bytes=100000000
```

**Expected:** VPN may be slower, but should be functional

### Latency Test

**Test ping times:**
```bash
# Direct
ping -c 10 8.8.8.8

# Through namespace
sudo ip netns exec vpnspace ping -c 10 8.8.8.8
```

**Expected:** Namespace adds 1-5ms overhead

### Concurrent Connections

**Test multiple simultaneous connections:**
```bash
# Start 10 concurrent downloads through proxy
for i in {1..10}; do
  curl --socks5-hostname 10.200.200.2:1081 -o /dev/null https://httpbin.org/bytes/1000000 &
done
wait
```

**Expected:** All connections succeed

## Long-Running Tests

### Stability Test (24 hours)

**Setup:**
```bash
./connect.sh

# Create monitoring script
cat > monitor.sh <<'EOF'
#!/bin/bash
while true; do
  echo "[$(date)] Testing connection..."
  IP=$(curl -s --socks5-hostname 10.200.200.2:1081 https://api.ipify.org)
  if [ -z "$IP" ]; then
    echo "FAILED!"
    exit 1
  fi
  echo "OK - IP: $IP"
  sleep 300  # Every 5 minutes
done
EOF

chmod +x monitor.sh
./monitor.sh > stability-test.log 2>&1 &
```

**After 24 hours:**
```bash
# Check log
tail -100 stability-test.log

# Verify connection still works
curl --socks5-hostname 10.200.200.2:1081 https://api.ipify.org

# Check for memory leaks
ps aux | grep -E "openvpn|sockd|socat"
# Note memory usage (RSS column)
```

**Expected:**
- Connection remains stable
- No memory leaks
- Consistent performance

### Reconnection Test

**Test automatic recovery:**
```bash
# After setup, manually kill OpenVPN
sudo pkill openvpn

# Wait a moment
sleep 5

# Test if proxy still works
curl --socks5-hostname 10.200.200.2:1081 https://api.ipify.org
```

**Expected:**
- Proxy fails (expected behavior)
- User must run disconnect and reconnect
- Future improvement: auto-reconnection

## Security Testing

### DNS Leak Test

**Verify DNS doesn't leak:**
```bash
# Check DNS server in namespace
sudo ip netns exec vpnspace cat /etc/resolv.conf
# Should show VPN DNS, not ISP DNS

# Online test
curl --socks5-hostname 10.200.200.2:1081 https://dnsleaktest.com
# Manually check results on website
```

**Expected:** No DNS leaks detected

### IP Leak Test

**Verify IP doesn't leak:**
```bash
# Test various IP detection methods
curl --socks5-hostname 10.200.200.2:1081 https://api.ipify.org
curl --socks5-hostname 10.200.200.2:1081 https://ifconfig.me
curl --socks5-hostname 10.200.200.2:1081 https://icanhazip.com

# All should show same VPN IP
```

### WebRTC Leak Test

**Test for WebRTC leaks:**
```bash
# This requires browser testing
# Use https://browserleaks.com/webrtc
```

**Manual test:**
1. Launch VSCode with proxy
2. Open internal browser
3. Visit https://browserleaks.com/webrtc
4. Verify only VPN IP is shown

## Automated Testing Script

Create comprehensive test suite:

```bash
cat > run-tests.sh <<'EOF'
#!/bin/bash

echo "=== VSCode SOCKS5 VPN Namespace Test Suite ==="
echo ""

NAMESPACE="test-vpn"
PORT=1081
PASSED=0
FAILED=0

# Test 1: Connect
echo "[TEST 1] Running connect script..."
./connect.sh <<INPUT
$NAMESPACE
/path/to/your/test.ovpn


1080
$PORT
8.8.8.8
n
y
INPUT

if [ $? -eq 0 ]; then
  echo "✓ PASSED: Connect script executed"
  ((PASSED++))
else
  echo "✗ FAILED: Connect script failed"
  ((FAILED++))
  exit 1
fi

# Test 2: Namespace exists
echo "[TEST 2] Checking namespace..."
if sudo ip netns list | grep -q "$NAMESPACE"; then
  echo "✓ PASSED: Namespace exists"
  ((PASSED++))
else
  echo "✗ FAILED: Namespace not found"
  ((FAILED++))
fi

# Test 3: VPN IP
echo "[TEST 3] Testing VPN IP..."
VPN_IP=$(curl -s --connect-timeout 10 --socks5-hostname 10.200.200.2:$PORT https://api.ipify.org)
if [ -n "$VPN_IP" ]; then
  echo "✓ PASSED: VPN IP obtained: $VPN_IP"
  ((PASSED++))
else
  echo "✗ FAILED: Could not get VPN IP"
  ((FAILED++))
fi

# Test 4: Host IP unchanged
echo "[TEST 4] Testing host IP..."
HOST_IP=$(curl -s https://api.ipify.org)
if [ "$HOST_IP" != "$VPN_IP" ]; then
  echo "✓ PASSED: Host IP different from VPN IP"
  ((PASSED++))
else
  echo "✗ FAILED: Host IP same as VPN IP"
  ((FAILED++))
fi

# Test 5: DNS resolution
echo "[TEST 5] Testing DNS..."
if sudo ip netns exec $NAMESPACE nslookup google.com > /dev/null 2>&1; then
  echo "✓ PASSED: DNS resolution works"
  ((PASSED++))
else
  echo "✗ FAILED: DNS resolution failed"
  ((FAILED++))
fi

# Test 6: Disconnect
echo "[TEST 6] Running disconnect script..."
./disconnect.sh <<INPUT
n
n
INPUT

if [ $? -eq 0 ]; then
  echo "✓ PASSED: Disconnect script executed"
  ((PASSED++))
else
  echo "✗ FAILED: Disconnect script failed"
  ((FAILED++))
fi

# Test 7: Cleanup verification
echo "[TEST 7] Verifying cleanup..."
if ! sudo ip netns list | grep -q "$NAMESPACE"; then
  echo "✓ PASSED: Namespace cleaned up"
  ((PASSED++))
else
  echo "✗ FAILED: Namespace still exists"
  ((FAILED++))
fi

echo ""
echo "=== Test Results ==="
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo "Total:  $((PASSED + FAILED))"

if [ $FAILED -eq 0 ]; then
  echo "✓ ALL TESTS PASSED"
  exit 0
else
  echo "✗ SOME TESTS FAILED"
  exit 1
fi
EOF

chmod +x run-tests.sh
```

## Test Report Template

After testing, document results:

```markdown
# Test Report - [Platform Name]

**Date:** [Date]
**Tester:** [Your Name]
**Platform:** [OS Name and Version]
**Script Version:** 1.0

## Environment
- OS: 
- Kernel: 
- Network: 
- VPN Provider: 

## Test Results

### Functionality Tests
- [ ] Connect script executes
- [ ] Dependencies installed
- [ ] Namespace created
- [ ] VPN connected
- [ ] Proxy working
- [ ] Disconnect successful

### Verification Tests
- [ ] VPN IP different from host IP
- [ ] DNS not leaking
- [ ] Multiple namespaces work
- [ ] Cleanup complete

### Performance Tests
- [ ] Download speed acceptable
- [ ] Latency reasonable
- [ ] Stable for 24 hours

## Issues Found
1. [Issue description]
2. [Issue description]

## Notes
[Any additional observations]

## Conclusion
[ ] Scripts work correctly
[ ] Scripts need fixes
```

---

**Testing Status:**
- Ubuntu: ✅ Ready for testing
- Arch: ✅ Ready for testing
- Fedora: ✅ Ready for testing
- Manjaro: ✅ Ready for testing
- openSUSE: ✅ Ready for testing
- Kali: ✅ Ready for testing
- macOS: ✅ Ready for testing
- Windows: ✅ Ready for testing

**Next Steps:**
1. Run tests on each platform
2. Document results
3. Fix any issues found
4. Update scripts based on feedback
