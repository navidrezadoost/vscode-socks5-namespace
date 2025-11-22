# VSCode SOCKS5 VPN Namespace - openSUSE

## Prerequisites

This script requires the following packages to be installed:

- `openvpn` - OpenVPN client
- `dante-server` - SOCKS5 server (provides `sockd`)
- `socat` - Socket relay
- `curl` - For testing connectivity
- `iproute2` - Network namespace management (usually pre-installed)
- `iptables` - Firewall rules (usually pre-installed)

## Quick Installation

### Install Dependencies

**For openSUSE Leap and Tumbleweed:**
```bash
sudo zypper install openvpn dante-server socat curl iproute2 iptables
```

## Usage

### Connect to VPN

```bash
cd /path/to/dev-socks-isolation/linux/openSUSE
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

## openSUSE-Specific Notes

### Firewall Configuration

openSUSE may use either `SuSEfirewall2` (older versions) or `firewalld` (newer versions).

#### For firewalld (Leap 15.x+, Tumbleweed):

```bash
# Allow traffic from the VPN namespace
sudo firewall-cmd --permanent --zone=trusted --add-source=10.200.200.0/24
sudo firewall-cmd --permanent --zone=public --add-masquerade
sudo firewall-cmd --reload
```

#### For SuSEfirewall2 (older Leap versions):

Edit `/etc/sysconfig/SuSEfirewall2`:
```bash
sudo vi /etc/sysconfig/SuSEfirewall2
```

Add to `FW_FORWARD_ALWAYS_INOUT_DEV`:
```
FW_FORWARD_ALWAYS_INOUT_DEV="veth0"
```

Then restart the firewall:
```bash
sudo systemctl restart SuSEfirewall2
```

### AppArmor Considerations

openSUSE uses AppArmor for security. If you encounter permission issues:

```bash
# Check AppArmor status
sudo aa-status

# Set OpenVPN profile to complain mode (for testing)
sudo aa-complain /usr/sbin/openvpn
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
After=network-online.target wickedd.service
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/path/to/dev-socks-isolation/linux/openSUSE/connect.sh
ExecStop=/path/to/dev-socks-isolation/linux/openSUSE/disconnect.sh
StandardInput=tty-force

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl daemon-reload
sudo systemctl enable vscode-vpn-proxy.service
```

### Wicked Network Manager

openSUSE uses Wicked as the default network manager. The script is compatible with Wicked's network namespace handling.

If you experience issues, check Wicked status:
```bash
sudo wicked show all
```

## Compatibility

This script is compatible with:
- openSUSE Leap (15.3, 15.4, 15.5, 15.6 and newer)
- openSUSE Tumbleweed (rolling release)
- SUSE Linux Enterprise Server (SLES) 15

## Troubleshooting

### Issue: "dante-server not found"

**Solution:** The package might be in a different repository:
```bash
# Search for dante
sudo zypper search dante

# If not found, add OSS repository
sudo zypper addrepo https://download.opensuse.org/distribution/leap/15.6/repo/oss/ OSS
sudo zypper refresh
sudo zypper install dante-server
```

### Issue: zypper wants to change vendor

openSUSE may show vendor change warnings. You can accept them safely:
```bash
sudo zypper install --allow-vendor-change dante-server
```

### Issue: Network interface not detected

List your network interfaces:
```bash
ip link show
# Or use YaST
sudo yast2 lan
```

### Issue: Firewall blocking connections

**Check which firewall is running:**
```bash
sudo systemctl status firewalld
sudo systemctl status SuSEfirewall2
```

**For firewalld:**
```bash
sudo firewall-cmd --list-all
sudo firewall-cmd --permanent --zone=trusted --add-source=10.200.200.0/24
sudo firewall-cmd --reload
```

**For SuSEfirewall2:**
```bash
# Use YaST to configure
sudo yast2 firewall
```

### Issue: AppArmor denying permissions

**Check audit logs:**
```bash
sudo journalctl -xe | grep -i apparmor
sudo aa-notify -s 1 -v
```

**Disable AppArmor for OpenVPN (not recommended):**
```bash
sudo ln -s /etc/apparmor.d/usr.sbin.openvpn /etc/apparmor.d/disable/
sudo apparmor_parser -R /etc/apparmor.d/usr.sbin.openvpn
```

## Advanced Configuration

### Using YaST for Package Management

You can also use YaST (openSUSE's system management tool) to install packages:

```bash
sudo yast2 sw_single
# Search for: openvpn, dante-server, socat
```

### Snapper Integration

openSUSE uses Snapper for filesystem snapshots. Before making system changes, create a snapshot:

```bash
sudo snapper create --description "Before VPN namespace setup"
```

If something goes wrong:
```bash
sudo snapper list
sudo snapper rollback <snapshot-number>
```

### Btrfs Considerations

openSUSE defaults to Btrfs. The script works normally with Btrfs filesystems.

## Support

For openSUSE-specific issues, check:
- [openSUSE OpenVPN Documentation](https://en.opensuse.org/OpenVPN)
- [openSUSE Network Documentation](https://doc.opensuse.org/documentation/leap/reference/html/book-reference/cha-network.html)
- [openSUSE Forums](https://forums.opensuse.org/)
