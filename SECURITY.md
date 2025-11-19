# Security Policy

## Overview

This project creates isolated network environments for VPN connections. Security is a critical concern, as the tool:
- Modifies network configurations
- Requires root/administrator privileges
- Handles VPN credentials
- Manages firewall rules

## Security Model

### Threat Model

**What This Tool Protects Against:**
- ✅ Accidental exposure of development traffic outside VPN
- ✅ System-wide VPN effects interfering with local network access
- ✅ VPN credential leakage to non-VPN applications
- ✅ Traffic mixing between VPN and non-VPN applications

**What This Tool Does NOT Protect Against:**
- ❌ Malicious VPN providers
- ❌ Compromised OpenVPN configurations
- ❌ System-level malware
- ❌ Network-level attacks (use firewall)
- ❌ Physical access to the machine

### Trust Boundaries

```
┌─────────────────────────────────────────────┐
│           Untrusted Network                 │
│        (Internet, VPN Provider)             │
└──────────────┬──────────────────────────────┘
               │ Encrypted VPN Tunnel
               │
┌──────────────▼──────────────────────────────┐
│         VPN Namespace (Isolated)            │
│  - OpenVPN process (trusted)                │
│  - Dante SOCKS server (trusted)             │
│  - User applications via SOCKS (trusted)    │
└──────────────┬──────────────────────────────┘
               │ Virtual Network Interface
               │
┌──────────────▼──────────────────────────────┐
│           Host System (Trusted)             │
│  - User applications (trusted)              │
│  - Local network access (trusted)           │
└─────────────────────────────────────────────┘
```

## Security Best Practices

### 1. VPN Configuration Security

#### Protect Your .ovpn Files

**File Permissions:**
```bash
# Linux/macOS - Make config readable only by you
chmod 600 /path/to/your/config.ovpn

# Verify permissions
ls -l /path/to/your/config.ovpn
# Should show: -rw------- (600)
```

**Credential Storage:**
```bash
# NEVER commit .ovpn files to Git
echo "*.ovpn" >> .gitignore

# Store credentials in a separate file referenced by .ovpn
# In your .ovpn file:
auth-user-pass /path/to/credentials.txt

# Protect credentials file
chmod 600 /path/to/credentials.txt
```

**Encryption at Rest:**
```bash
# Use encrypted partitions for VPN configs
# Or use tools like EncFS, VeraCrypt

# macOS Keychain example
security add-generic-password \
  -a "VPN Username" \
  -s "OpenVPN" \
  -w "password"
```

### 2. Network Security

#### Firewall Rules

**Linux - iptables:**
```bash
# Only allow specific namespace traffic
sudo iptables -A OUTPUT -m owner --uid-owner vpn-user -j ACCEPT
sudo iptables -A OUTPUT -j DROP

# Log suspicious traffic
sudo iptables -A OUTPUT -j LOG --log-prefix "VPN-LEAK: "
```

**Linux - nftables:**
```bash
# Modern alternative to iptables
nft add table inet vpn-filter
nft add chain inet vpn-filter output { type filter hook output priority 0\; }
nft add rule inet vpn-filter output oifname "tun0" accept
```

**macOS - pf:**
```bash
# Add to /etc/pf.conf
block out all
pass out on utun0 all
```

**Windows Firewall:**
```powershell
# Block non-VPN traffic for specific apps
New-NetFirewallRule -DisplayName "VSCode VPN Only" `
  -Direction Outbound `
  -Program "C:\Program Files\Microsoft VS Code\Code.exe" `
  -Action Block

# Allow through SOCKS proxy
New-NetFirewallRule -DisplayName "SOCKS Proxy" `
  -Direction Outbound `
  -Protocol TCP `
  -LocalPort 1080 `
  -Action Allow
```

#### DNS Leak Prevention

**Verify DNS is not leaking:**
```bash
# Test DNS from namespace
sudo ip netns exec vpnspace nslookup google.com

# Should use VPN's DNS server, not your ISP's
# Check with:
sudo ip netns exec vpnspace cat /etc/resolv.conf

# Test for DNS leaks online
curl --socks5-hostname 10.200.200.2:1081 https://dnsleaktest.com
```

**Force DNS through VPN:**
```bash
# In OpenVPN config, add:
dhcp-option DNS 8.8.8.8
dhcp-option DNS 8.8.4.4

# Or modify the script to use VPN-provided DNS
```

### 3. Process Isolation

#### Running as Non-Root User

**Create dedicated VPN user (Linux):**
```bash
# Create user for VPN processes
sudo useradd -r -s /bin/false vpnuser

# Run OpenVPN as vpnuser
sudo ip netns exec vpnspace sudo -u vpnuser openvpn --config /path/to/config.ovpn
```

#### Limiting Process Capabilities

**Linux capabilities:**
```bash
# Give only necessary capabilities
sudo setcap cap_net_admin,cap_net_bind_service+eip /usr/sbin/openvpn

# Verify
getcap /usr/sbin/openvpn
```

### 4. Credential Management

#### Never Hardcode Credentials

**Bad Practice:**
```bash
# DON'T DO THIS
USERNAME="myusername"
PASSWORD="mypassword"
```

**Good Practice:**
```bash
# Use auth-user-pass in .ovpn
auth-user-pass /secure/path/credentials.txt

# credentials.txt format:
# username
# password

# Protect the file
chmod 600 /secure/path/credentials.txt
```

#### Use System Credential Stores

**Linux - GNOME Keyring:**
```bash
# Store password in keyring
secret-tool store --label='VPN Password' vpn password

# Retrieve in script
PASSWORD=$(secret-tool lookup vpn password)
```

**macOS - Keychain:**
```bash
# Store password
security add-generic-password -a "$USER" -s "OpenVPN" -w "password"

# Retrieve in script
security find-generic-password -a "$USER" -s "OpenVPN" -w
```

**Windows - Credential Manager:**
```powershell
# Store credential
cmdkey /generic:"OpenVPN" /user:"username" /pass:"password"

# Retrieve in script
$cred = Get-StoredCredential -Target "OpenVPN"
```

### 5. Log Security

#### Secure Log Files

**Restrict log access:**
```bash
# Logs may contain sensitive information
sudo chmod 600 /tmp/openvpn*.log
sudo chmod 600 /tmp/danted*.log

# Or use /var/log with proper permissions
sudo mkdir -p /var/log/vpn-namespace
sudo chmod 700 /var/log/vpn-namespace
```

#### Log Rotation

**Prevent log files from growing too large:**
```bash
# Create /etc/logrotate.d/vpn-namespace
/tmp/openvpn*.log /tmp/danted*.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
    create 600 root root
}
```

#### Clean Logs on Disconnect

The disconnect script should clean logs:
```bash
# In disconnect script
sudo rm -f /tmp/openvpn*.log
sudo rm -f /tmp/danted*.log
```

### 6. Temporary File Security

#### Secure Temporary Directories

**Use private temp directories:**
```bash
# Create private temp dir
TEMP_DIR=$(mktemp -d)
chmod 700 "$TEMP_DIR"

# Clean up on exit
trap "rm -rf '$TEMP_DIR'" EXIT
```

#### Named Pipes and Sockets

**Secure socket creation:**
```bash
# Create socket with restrictive permissions
umask 077
socat UNIX-LISTEN:/tmp/vpn.sock,fork TCP:localhost:1080
```

## Security Checklist

### Before Running Scripts

- [ ] Verify script integrity (check hashes if downloaded)
- [ ] Review script contents (understand what it does)
- [ ] Ensure .ovpn file has correct permissions (600)
- [ ] Verify OpenVPN config doesn't contain plaintext credentials
- [ ] Check firewall rules won't block VPN
- [ ] Ensure you trust your VPN provider
- [ ] Backup current network configuration

### After Running Scripts

- [ ] Verify namespace was created: `sudo ip netns list`
- [ ] Check VPN connection: Test public IP through proxy
- [ ] Verify DNS is not leaking: `dnsleaktest.com`
- [ ] Check no processes are running as root unnecessarily
- [ ] Verify firewall rules are correct: `sudo iptables -L -n`
- [ ] Check log files for errors or warnings
- [ ] Verify host IP is unchanged

### Regular Maintenance

- [ ] Update OpenVPN regularly: `sudo apt update && sudo apt upgrade openvpn`
- [ ] Rotate VPN credentials periodically
- [ ] Review firewall logs for suspicious activity
- [ ] Check for script updates
- [ ] Audit namespace processes: `sudo ip netns exec vpnspace ps aux`
- [ ] Review and clean old log files

## Vulnerability Reporting

### Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

### Reporting a Vulnerability

If you discover a security vulnerability:

**DO:**
1. **Email the maintainer privately** (not via public issues)
2. Include detailed description of the vulnerability
3. Provide steps to reproduce
4. Allow reasonable time for a fix (90 days)
5. Coordinate disclosure timing

**DON'T:**
1. Publicly disclose before a fix is available
2. Exploit the vulnerability maliciously
3. Demand payment for disclosure

**Email:** [Your security contact email]

**Response Time:**
- Initial response: Within 48 hours
- Status update: Within 7 days
- Fix timeline: Depends on severity (critical: 30 days, high: 60 days)

## Known Security Considerations

### 1. Root Privilege Requirement

**Issue:** Scripts require root/sudo access.

**Mitigation:**
- Scripts use sudo only when necessary
- Processes drop privileges where possible
- Use sudo timeout to limit exposure
- Consider using sudoers configuration for specific commands

**Sudoers Configuration:**
```bash
# Allow VPN commands without password
# Edit with: sudo visudo
username ALL=(ALL) NOPASSWD: /usr/sbin/openvpn
username ALL=(ALL) NOPASSWD: /usr/sbin/ip
username ALL=(ALL) NOPASSWD: /usr/sbin/iptables
```

### 2. Network Namespace Escape

**Issue:** Processes in namespace could theoretically escape.

**Mitigation:**
- Keep kernel updated
- Use AppArmor/SELinux profiles
- Regularly audit namespace processes
- Use cgroups for additional isolation

**AppArmor Profile Example:**
```
# /etc/apparmor.d/usr.sbin.openvpn
#include <tunables/global>

/usr/sbin/openvpn {
  #include <abstractions/base>
  #include <abstractions/nameservice>
  
  capability net_admin,
  capability net_bind_service,
  
  /etc/openvpn/** r,
  /tmp/openvpn*.log w,
  
  # Deny access to sensitive files
  deny /etc/shadow r,
  deny /root/** r,
}
```

### 3. Traffic Correlation

**Issue:** Adversary might correlate VPN and non-VPN traffic timing.

**Mitigation:**
- Use VPN with strong encryption (AES-256)
- Enable VPN kill switch
- Consider using Tor over VPN for high-risk scenarios
- Add traffic padding (some VPN providers support this)

### 4. macOS/Windows Limitations

**Issue:** macOS and Windows don't have full namespace isolation.

**Mitigation:**
- macOS: Be aware all VPN interface traffic is affected
- Windows: WSL2 provides good isolation but adds complexity
- For maximum security on these platforms, use VM with Linux
- Document limitations clearly to users

### 5. SOCKS Proxy Security

**Issue:** SOCKS proxy could be accessed by unauthorized applications.

**Mitigation:**
- Bind SOCKS to localhost only (default)
- Use authentication if Dante supports it
- Firewall rules to limit access
- Monitor SOCKS connections

**Authenticated SOCKS:**
```bash
# In danted.conf
socksmethod: username

# Add user
user.privileged: root
user.unprivileged: nobody
```

## Security Hardening Options

### 1. Enable OpenVPN Security Features

**In .ovpn config:**
```
# Strong encryption
cipher AES-256-GCM
auth SHA512

# Perfect Forward Secrecy
tls-cipher TLS-ECDHE-RSA-WITH-AES-256-GCM-SHA384

# TLS authentication
tls-auth ta.key 1

# Certificate verification
remote-cert-tls server
verify-x509-name server_name name

# Prevent DNS leaks
block-outside-dns
dhcp-option DNS 8.8.8.8
dhcp-option DNS 8.8.4.4

# Kill switch (script-based)
up /etc/openvpn/up.sh
down /etc/openvpn/down.sh
```

### 2. Network Namespace Additional Security

**Add SELinux context (Fedora/RHEL):**
```bash
# Label namespace
sudo semanage fcontext -a -t vpn_namespace_t "/etc/netns/vpnspace(/.*)?"
sudo restorecon -R /etc/netns/vpnspace
```

**Add seccomp filtering:**
```bash
# Restrict syscalls available to namespace processes
# Create seccomp profile: /etc/seccomp/vpn-namespace.json
```

### 3. Enable Audit Logging

**Linux auditd:**
```bash
# Monitor network namespace creation
sudo auditctl -a always,exit -F arch=b64 -S setns -k namespace

# Monitor OpenVPN execution
sudo auditctl -w /usr/sbin/openvpn -p x -k vpn-execution

# Monitor VPN config access
sudo auditctl -w /etc/openvpn/ -p r -k vpn-config-access
```

### 4. Implement Kill Switch

**Prevent traffic if VPN drops:**
```bash
# Add to connect script after VPN starts
sudo iptables -I OUTPUT ! -o tun0 -m owner --uid-owner $(id -u) -j DROP
sudo iptables -I OUTPUT -o tun0 -j ACCEPT

# Allow local network
sudo iptables -I OUTPUT -d 192.168.0.0/16 -j ACCEPT
sudo iptables -I OUTPUT -d 10.0.0.0/8 -j ACCEPT
```

## Compliance Considerations

### GDPR (EU)

- Ensure VPN provider is GDPR compliant
- Document data flows
- Implement data minimization (don't log unnecessarily)
- Provide user control over data

### Industry-Specific

**HIPAA (Healthcare):**
- Use HIPAA-compliant VPN provider
- Encrypt PHI in transit
- Maintain audit logs
- Implement access controls

**PCI DSS (Payment Cards):**
- Use strong encryption (AES-256)
- Maintain firewall rules
- Implement access logging
- Regular security updates

## Security Resources

### Testing Tools

**DNS Leak Tests:**
- https://dnsleaktest.com
- https://ipleak.net
- https://www.dnsleaktest.org

**IP Check:**
- https://api.ipify.org
- https://ifconfig.me
- https://icanhazip.com

**VPN Security:**
- https://www.comparitech.com/vpn/vpn-leak-test/
- https://www.perfect-privacy.com/en/tests/check-ip

### Further Reading

- [OpenVPN Security Guide](https://openvpn.net/community-resources/hardening-openvpn-security/)
- [Linux Network Namespaces](https://man7.org/linux/man-pages/man7/network_namespaces.7.html)
- [OWASP VPN Security](https://owasp.org/www-community/controls/VPN)
- [NSA VPN Best Practices](https://media.defense.gov/2021/Sep/28/2002863184/-1/-1/0/CSI_SELECTING-AND-USING-VPNS.PDF)

## Incident Response

### If You Suspect a Security Breach

1. **Immediately disconnect:**
   ```bash
   ./disconnect.sh
   ```

2. **Check for suspicious processes:**
   ```bash
   ps aux | grep -E "openvpn|sockd|socat"
   sudo ip netns list
   ```

3. **Review logs:**
   ```bash
   sudo cat /tmp/openvpn*.log
   sudo journalctl -xe | grep -E "openvpn|vpn"
   ```

4. **Check network connections:**
   ```bash
   sudo netstat -tunapl | grep -E "1080|1081"
   sudo ss -tunapl | grep -E "openvpn|sockd"
   ```

5. **Change VPN credentials**

6. **Report to VPN provider if necessary**

7. **Report to project maintainers if it's a script vulnerability**

---

**Last Updated:** November 2025  
**Version:** 1.0  
**Next Review:** February 2026
