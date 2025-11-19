# VSCode SOCKS5 VPN Proxy Disconnect - Windows (WSL2)
# PowerShell script to teardown VPN + SOCKS5 in WSL2

#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  VSCode SOCKS5 VPN Proxy Disconnect - Windows (WSL2)    ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

# Load configuration
$configFile = "$env:TEMP\vpn-wsl-config.txt"
if (Test-Path $configFile) {
    Write-Host "Loading saved configuration..." -ForegroundColor Yellow
    $config = Get-Content $configFile | ConvertFrom-StringData
    $socksPort = $config.SOCKS_PORT
    $wslIP = $config.WSL_IP
    Write-Host "✓ Configuration loaded" -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host "No saved configuration found." -ForegroundColor Yellow
    $socksPort = Read-Host "Enter SOCKS5 port (default: 1080)"
    if ([string]::IsNullOrWhiteSpace($socksPort)) { $socksPort = "1080" }
    Write-Host ""
}

# Cleanup script for WSL
$wslCleanupScript = @"
#!/bin/bash
NS='vpnspace'

echo '[1/6] Terminating processes...'
sudo pkill -f 'openvpn' 2>/dev/null || true
sudo pkill -f 'sockd' 2>/dev/null || true
sudo pkill -f 'socat' 2>/dev/null || true
sleep 2

sudo pkill -9 -f 'openvpn' 2>/dev/null || true
sudo pkill -9 -f 'sockd' 2>/dev/null || true

echo '[2/6] Deleting network namespace...'
sudo ip netns delete `$NS 2>/dev/null || true

echo '[3/6] Removing virtual interfaces...'
sudo ip link delete veth0 2>/dev/null || true

echo '[4/6] Removing iptables rules...'
EXT_IF=`$(ip route | grep default | awk '{print `$5}' | head -1)
HOST_IP=`$(ip addr show `$EXT_IF | grep 'inet ' | awk '{print `$2}' | cut -d/ -f1 | head -1)

sudo iptables -D FORWARD -i veth0 -o `$EXT_IF -j ACCEPT 2>/dev/null || true
sudo iptables -D FORWARD -i `$EXT_IF -o veth0 -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || true
sudo iptables -t nat -D POSTROUTING -s 10.200.200.0/24 -o `$EXT_IF -j SNAT --to-source `$HOST_IP 2>/dev/null || true

echo '[5/6] Cleaning up temporary files...'
sudo rm -f /tmp/danted_`$NS.conf
sudo rm -f /tmp/danted.log
sudo rm -f /tmp/openvpn.log
sudo rm -f /tmp/vpn-config.ovpn
sudo rm -f /etc/netns/`$NS/resolv.conf 2>/dev/null
sudo rmdir /etc/netns/`$NS 2>/dev/null || true

echo '[6/6] Cleanup completed!'
"@

# Save and execute cleanup script in WSL
$tempScript = [System.IO.Path]::GetTempFileName()
$wslCleanupScript | Out-File -FilePath $tempScript -Encoding ASCII

Write-Host "Running cleanup in WSL..." -ForegroundColor Yellow
wsl cp (Convert-Path $tempScript).Replace('\', '/').Replace('C:', '/mnt/c') /tmp/wsl-vpn-cleanup.sh
wsl chmod +x /tmp/wsl-vpn-cleanup.sh
wsl bash /tmp/wsl-vpn-cleanup.sh

# Remove port forwarding
Write-Host ""
Write-Host "Removing Windows port forwarding..." -ForegroundColor Yellow
netsh interface portproxy delete v4tov4 listenport=$socksPort listenaddress=127.0.0.1 2>$null
Write-Host "✓ Port forwarding removed" -ForegroundColor Green

# Check for VSCode instances
Write-Host ""
Write-Host "Checking for VSCode instances..." -ForegroundColor Yellow
$vscodeProcesses = Get-Process | Where-Object { $_.Name -like "*code*" -and $_.CommandLine -like "*socks5*" }
if ($vscodeProcesses) {
    $closeVSCode = Read-Host "Close VSCode instances using the proxy? (y/N)"
    if ($closeVSCode -eq "y" -or $closeVSCode -eq "Y") {
        $vscodeProcesses | Stop-Process -Force
        Write-Host "✓ VSCode instances closed" -ForegroundColor Green
    } else {
        Write-Host "VSCode instances left running" -ForegroundColor Yellow
    }
} else {
    Write-Host "No VSCode instances found using the proxy" -ForegroundColor Yellow
}

# Clean up config file
if (Test-Path $configFile) {
    Remove-Item $configFile
}

# Clean up temp scripts
Remove-Item $tempScript -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║           Cleanup Completed Successfully!                ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "All resources have been released:" -ForegroundColor White
Write-Host "  • WSL network namespace deleted"
Write-Host "  • Virtual interfaces removed"
Write-Host "  • OpenVPN and Dante processes terminated"
Write-Host "  • Windows port forwarding removed"
Write-Host "  • Temporary files cleaned"
Write-Host ""
Write-Host "✓ System is now clean. You can safely re-run the connect script anytime." -ForegroundColor Green
Write-Host ""
