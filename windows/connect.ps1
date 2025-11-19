# VSCode SOCKS5 VPN Proxy - Windows (WSL2)
# PowerShell script to setup OpenVPN + SOCKS5 in WSL2

# Requires Administrator privileges
#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  VSCode SOCKS5 VPN Proxy - Windows (WSL2)                ║" -ForegroundColor Green
Write-Host "║  OpenVPN + SOCKS5 proxy via WSL2                         ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

# Check if WSL2 is installed
Write-Host "Checking WSL2 installation..." -ForegroundColor Yellow
$wslVersion = wsl --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: WSL2 is not installed!" -ForegroundColor Red
    Write-Host ""
    Write-Host "To install WSL2:" -ForegroundColor Yellow
    Write-Host "1. Open PowerShell as Administrator" -ForegroundColor Yellow
    Write-Host "2. Run: wsl --install" -ForegroundColor Yellow
    Write-Host "3. Restart your computer" -ForegroundColor Yellow
    Write-Host "4. Run this script again" -ForegroundColor Yellow
    exit 1
}

# Check if a WSL distribution is installed
Write-Host "Checking WSL distributions..." -ForegroundColor Yellow
$wslDistros = wsl --list --quiet
if ($wslDistros.Count -eq 0) {
    Write-Host "No WSL distributions found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Install a distribution:" -ForegroundColor Yellow
    Write-Host "  wsl --install -d Ubuntu" -ForegroundColor Yellow
    exit 1
}

# Get default WSL distribution
$defaultDistro = wsl --list --quiet | Select-Object -First 1
Write-Host "✓ Using WSL distribution: $defaultDistro" -ForegroundColor Green
Write-Host ""

# Windows-specific notice
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host "  ⚠️  WINDOWS WSL2 APPROACH  ⚠️" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host ""
Write-Host "This script sets up VPN + SOCKS5 proxy in WSL2." -ForegroundColor White
Write-Host ""
Write-Host "How it works:" -ForegroundColor White
Write-Host "  1. OpenVPN runs inside WSL2 Linux environment" -ForegroundColor White
Write-Host "  2. SOCKS5 proxy created in WSL2" -ForegroundColor White
Write-Host "  3. Port forwarded to Windows host" -ForegroundColor White
Write-Host "  4. VSCode on Windows uses the SOCKS5 proxy" -ForegroundColor White
Write-Host ""
Write-Host "Advantages:" -ForegroundColor Green
Write-Host "  ✓ True Linux namespace isolation (in WSL2)" -ForegroundColor Green
Write-Host "  ✓ Only VSCode uses VPN" -ForegroundColor Green
Write-Host "  ✓ Windows host IP unchanged" -ForegroundColor Green
Write-Host ""

$continue = Read-Host "Continue with WSL2 setup? (Y/n)"
if ($continue -eq "n" -or $continue -eq "N") {
    Write-Host "Setup cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host ""

# Collect configuration
Write-Host "Configuration Setup" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow

# OpenVPN config file
do {
    $ovpnConfig = Read-Host "Enter path to your OpenVPN config file (Windows path)"
    if (Test-Path $ovpnConfig) {
        break
    } else {
        Write-Host "File not found. Please enter a valid path." -ForegroundColor Red
    }
} while ($true)

# Convert Windows path to WSL path
$wslPath = $ovpnConfig -replace '\\', '/' -replace ':', ''
$wslPath = "/mnt/" + $wslPath.Substring(0, 1).ToLower() + $wslPath.Substring(1)

# SOCKS port
$socksPort = Read-Host "Enter SOCKS5 port (default: 1080)"
if ([string]::IsNullOrWhiteSpace($socksPort)) { $socksPort = "1080" }

# DNS server
$dnsServer = Read-Host "Enter DNS server (default: 8.8.8.8)"
if ([string]::IsNullOrWhiteSpace($dnsServer)) { $dnsServer = "8.8.8.8" }

# Launch VSCode
$launchVSCode = Read-Host "Launch VSCode with proxy after setup? (Y/n)"
if ([string]::IsNullOrWhiteSpace($launchVSCode)) { $launchVSCode = "Y" }

Write-Host ""
Write-Host "Configuration Summary:" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host "OpenVPN Config: $ovpnConfig"
Write-Host "WSL Path: $wslPath"
Write-Host "SOCKS Port: $socksPort"
Write-Host "DNS Server: $dnsServer"
Write-Host "Launch VSCode: $launchVSCode"
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host ""

$confirm = Read-Host "Proceed with setup? (Y/n)"
if ($confirm -eq "n" -or $confirm -eq "N") {
    Write-Host "Setup cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "Starting setup..." -ForegroundColor Green

# Copy OpenVPN config to WSL
Write-Host "[1/6] Copying OpenVPN config to WSL..." -ForegroundColor Yellow
wsl sudo cp "$wslPath" /tmp/vpn-config.ovpn

# Install dependencies in WSL
Write-Host "[2/6] Installing dependencies in WSL..." -ForegroundColor Yellow
wsl sudo apt-get update
wsl sudo apt-get install -y openvpn dante-server socat curl iproute2 iptables

# Create and run the setup script in WSL
Write-Host "[3/6] Creating VPN namespace in WSL..." -ForegroundColor Yellow

$wslScript = @"
#!/bin/bash
set -e

NS='vpnspace'
OVPN_CONFIG='/tmp/vpn-config.ovpn'
EXT_IF=`$(ip route | grep default | awk '{print `$5}' | head -1)
HOST_IP=`$(ip addr show `$EXT_IF | grep 'inet ' | awk '{print `$2}' | cut -d/ -f1 | head -1)
SOCKS_PORT=$socksPort
LOCAL_PROXY_PORT=$socksPort
DNS_SERVER='$dnsServer'

echo 'Cleaning up previous instances...'
sudo pkill -f 'openvpn.*vpn-config.ovpn' 2>/dev/null || true
sudo pkill -f 'sockd' 2>/dev/null || true
sudo pkill -f 'socat.*`$LOCAL_PROXY_PORT' 2>/dev/null || true
sudo ip netns delete `$NS 2>/dev/null || true
sudo ip link delete veth0 2>/dev/null || true
sleep 1

echo 'Creating network namespace...'
sudo ip netns add `$NS
sudo ip netns exec `$NS ip link set dev lo up

echo 'Setting up virtual network interfaces...'
sudo ip link add veth0 type veth peer name veth1
sudo ip link set veth0 up
sudo ip link set veth1 netns `$NS up
sudo ip addr add 10.200.200.1/24 dev veth0
sudo ip netns exec `$NS ip addr add 10.200.200.2/24 dev veth1
sudo ip netns exec `$NS ip route add default via 10.200.200.1 dev veth1

echo 'Configuring NAT...'
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward > /dev/null
sudo iptables -A FORWARD -i veth0 -o `$EXT_IF -j ACCEPT
sudo iptables -A FORWARD -i `$EXT_IF -o veth0 -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -t nat -A POSTROUTING -s 10.200.200.0/24 -o `$EXT_IF -j SNAT --to-source `$HOST_IP

echo 'Configuring DNS...'
sudo mkdir -p /etc/netns/`$NS
echo \"nameserver `$DNS_SERVER\" | sudo tee /etc/netns/`$NS/resolv.conf > /dev/null

echo 'Creating SOCKS5 configuration...'
cat | sudo tee /tmp/danted_`$NS.conf > /dev/null <<EOF
logoutput: /tmp/danted.log
internal: 127.0.0.1 port = `$SOCKS_PORT
external: tun0
socksmethod: none
clientmethod: none
user.privileged: root
user.unprivileged: nobody

client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: error
}

socks pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    command: bind connect udpassociate
    log: error
}
EOF

echo 'Starting OpenVPN...'
sudo ip netns exec `$NS openvpn --config `$OVPN_CONFIG --daemon --log /tmp/openvpn.log

echo 'Waiting for VPN connection...'
for i in {1..30}; do
    if sudo ip netns exec `$NS ip addr show tun0 2>/dev/null | grep -q 'inet'; then
        VPN_IP=`$(sudo ip netns exec `$NS ip addr show tun0 | grep 'inet ' | awk '{print `$2}' | cut -d/ -f1 | head -1)
        echo \"VPN connected! IP: `$VPN_IP\"
        break
    fi
    sleep 1
done

if ! sudo ip netns exec `$NS ip addr show tun0 >/dev/null 2>&1; then
    echo 'Error: VPN connection failed!'
    exit 1
fi

echo 'Starting SOCKS5 proxy...'
sudo ip netns exec `$NS sockd -f /tmp/danted_`$NS.conf -D &
sleep 3

echo 'Testing proxy...'
PROXY_IP=`$(sudo ip netns exec `$NS curl -s --connect-timeout 10 --socks5-hostname 127.0.0.1:`$SOCKS_PORT https://api.ipify.org)
if [[ -n \"`$PROXY_IP\" ]]; then
    echo \"Proxy working! Public IP: `$PROXY_IP\"
else
    echo 'Proxy test failed!'
    exit 1
fi

echo 'Exposing proxy to host...'
sudo ip netns exec `$NS socat TCP-LISTEN:`$LOCAL_PROXY_PORT,bind=10.200.200.2,reuseaddr,fork TCP:127.0.0.1:`$SOCKS_PORT &
sleep 2

echo 'Setup completed successfully!'
echo \"Proxy address: socks5://10.200.200.2:`$LOCAL_PROXY_PORT\"
"@

# Save script to temp file
$tempScript = [System.IO.Path]::GetTempFileName()
$wslScript | Out-File -FilePath $tempScript -Encoding ASCII

# Copy and execute script in WSL
wsl cp (Convert-Path $tempScript).Replace('\', '/').Replace('C:', '/mnt/c') /tmp/wsl-vpn-setup.sh
wsl chmod +x /tmp/wsl-vpn-setup.sh
wsl bash /tmp/wsl-vpn-setup.sh

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Setup failed in WSL!" -ForegroundColor Red
    exit 1
}

# Get WSL IP address
Write-Host "[4/6] Getting WSL IP address..." -ForegroundColor Yellow
$wslIP = wsl hostname -I | ForEach-Object { $_.Trim().Split(' ')[0] }
Write-Host "✓ WSL IP: $wslIP" -ForegroundColor Green

# Setup port forwarding (Windows to WSL)
Write-Host "[5/6] Setting up port forwarding..." -ForegroundColor Yellow
netsh interface portproxy delete v4tov4 listenport=$socksPort listenaddress=127.0.0.1 2>$null
netsh interface portproxy add v4tov4 listenport=$socksPort listenaddress=127.0.0.1 connectport=$socksPort connectaddress=$wslIP

# Test proxy from Windows
Write-Host "[6/6] Testing proxy from Windows..." -ForegroundColor Yellow
$proxyTest = curl.exe -s --connect-timeout 10 --socks5-hostname 127.0.0.1:$socksPort https://api.ipify.org
if ($proxyTest) {
    Write-Host "✓ Proxy accessible from Windows! Public IP: $proxyTest" -ForegroundColor Green
} else {
    Write-Host "Warning: Proxy test from Windows failed" -ForegroundColor Yellow
}

# Save configuration
$configFile = "$env:TEMP\vpn-wsl-config.txt"
@"
SOCKS_PORT=$socksPort
WSL_IP=$wslIP
"@ | Out-File -FilePath $configFile

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║              Setup Completed Successfully!               ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "Proxy Configuration:" -ForegroundColor Green
Write-Host "  SOCKS5 Address: socks5://127.0.0.1:$socksPort"
Write-Host "  WSL IP: $wslIP"
Write-Host ""
Write-Host "To use with VSCode:" -ForegroundColor Yellow
Write-Host "  code --proxy-server=`"socks5://127.0.0.1:$socksPort`""
Write-Host ""
Write-Host "To disconnect:" -ForegroundColor Yellow
Write-Host "  Run: .\disconnect.ps1"
Write-Host ""

# Launch VSCode
if ($launchVSCode -eq "Y" -or $launchVSCode -eq "y") {
    Write-Host "Launching VSCode with SOCKS5 proxy..." -ForegroundColor Yellow
    if (Get-Command code -ErrorAction SilentlyContinue) {
        Start-Process code -ArgumentList "--proxy-server=`"socks5://127.0.0.1:$socksPort`""
        Write-Host "✓ VSCode launched" -ForegroundColor Green
    } else {
        Write-Host "Warning: VSCode not found in PATH" -ForegroundColor Yellow
        Write-Host "You can manually launch it with: code --proxy-server=`"socks5://127.0.0.1:$socksPort`"" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "✓ All done!" -ForegroundColor Green
