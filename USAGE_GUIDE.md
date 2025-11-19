# Usage Guide: Configuring Applications with SOCKS5 Proxy

This guide explains how to configure various IDEs and applications to use the SOCKS5 proxy created by this project.

## Table of Contents
- [Understanding Your Proxy Configuration](#understanding-your-proxy-configuration)
- [Visual Studio Code (VSCode)](#visual-studio-code-vscode)
- [JetBrains IDEs](#jetbrains-ides)
- [Web Browsers](#web-browsers)
- [Git](#git)
- [Terminal Applications](#terminal-applications)
- [Docker](#docker)
- [Other Applications](#other-applications)

---

## Understanding Your Proxy Configuration

After running the connect script, your SOCKS5 proxy is available at:

```
SOCKS5 Address: socks5://10.200.200.2:1081
```

**Components:**
- **Protocol:** `socks5://`
- **Host:** `10.200.200.2` (virtual interface in namespace)
- **Port:** `1081` (default, customizable during setup)

**For localhost applications, you can also use:**
```
socks5://127.0.0.1:1081
```

---

## Visual Studio Code (VSCode)

### Method 1: Command Line (Recommended)

Launch VSCode with the proxy from terminal:

```bash
code --proxy-server="socks5://10.200.200.2:1081"
```

**Create a launcher script for convenience:**

```bash
# Create launcher
cat > ~/launch-vscode-vpn.sh <<'EOF'
#!/bin/bash
code --proxy-server="socks5://10.200.200.2:1081" "$@"
EOF

chmod +x ~/launch-vscode-vpn.sh

# Use it
~/launch-vscode-vpn.sh
~/launch-vscode-vpn.sh /path/to/project
```

### Method 2: Desktop Entry (Linux)

Create a desktop launcher that automatically uses the proxy:

```bash
cat > ~/.local/share/applications/vscode-vpn.desktop <<EOF
[Desktop Entry]
Name=VSCode (VPN)
Comment=Visual Studio Code with VPN Proxy
Exec=/usr/bin/code --proxy-server="socks5://10.200.200.2:1081" %F
Icon=code
Type=Application
StartupNotify=true
Categories=Development;IDE;
MimeType=text/plain;inode/directory;
Keywords=vscode;editor;vpn;
EOF

# Update desktop database
update-desktop-database ~/.local/share/applications/
```

Now you can launch "VSCode (VPN)" from your application menu!

### Method 3: VSCode Settings (Global)

Edit VSCode settings to always use the proxy:

**Via GUI:**
1. Open VSCode
2. Go to: `File` → `Preferences` → `Settings` (or `Code` → `Preferences` → `Settings` on macOS)
3. Search for: `proxy`
4. Set `Http: Proxy` to: `socks5://10.200.200.2:1081`

**Via settings.json:**

```bash
# Open settings
code ~/.config/Code/User/settings.json

# Add this configuration
```

```json
{
  "http.proxy": "socks5://10.200.200.2:1081",
  "http.proxyStrictSSL": false,
  "http.proxySupport": "on"
}
```

**Note:** This makes the proxy permanent. Remove these settings when not using VPN.

### Method 4: Environment Variable

Set proxy for current shell session:

```bash
export ELECTRON_PROXY="socks5://10.200.200.2:1081"
code
```

Add to your shell profile (`~/.bashrc`, `~/.zshrc`) for persistence:

```bash
# Add to ~/.bashrc or ~/.zshrc
alias code-vpn='ELECTRON_PROXY="socks5://10.200.200.2:1081" code'

# Then use
code-vpn
```

### Verify VSCode is Using the Proxy

1. Open VSCode with proxy configuration
2. Open Developer Tools: `Help` → `Toggle Developer Tools`
3. Go to `Network` tab
4. Try accessing an extension or GitHub
5. Check the IP:
   - Open terminal in VSCode: `` Ctrl+` ``
   - Run: `curl https://api.ipify.org`
   - Should show your VPN IP

### VSCode Extensions Configuration

Some extensions may need proxy configuration:

**GitLens, GitHub Copilot, Remote-SSH, etc.:**

```json
{
  "http.proxy": "socks5://10.200.200.2:1081",
  "http.proxyStrictSSL": false,
  "github.gitProtocol": "https",
  "remote.SSH.enableDynamicForwarding": false
}
```

---

## JetBrains IDEs

JetBrains IDEs (IntelliJ IDEA, PyCharm, WebStorm, PhpStorm, GoLand, RubyMine, CLion, etc.) have built-in proxy support.

### Configure Proxy in JetBrains IDEs

#### Method 1: GUI Configuration (Recommended)

1. **Open Settings:**
   - `File` → `Settings` (Windows/Linux)
   - `IntelliJ IDEA` → `Preferences` (macOS)
   - Or press: `Ctrl+Alt+S` (Windows/Linux) / `Cmd+,` (macOS)

2. **Navigate to Proxy Settings:**
   - Go to: `Appearance & Behavior` → `System Settings` → `HTTP Proxy`

3. **Configure Manual Proxy:**
   - Select: **`Manual proxy configuration`**
   - Select: **`SOCKS`** radio button
   - **Host name:** `10.200.200.2`
   - **Port number:** `1081`
   - ✅ Check: **`Proxy authentication`** (if your SOCKS requires it, usually NOT needed)
   - **No proxy for:** `localhost,127.0.0.1` (optional)

4. **Test Connection:**
   - Click: **`Check connection`**
   - Enter test URL: `https://www.google.com`
   - Should show: ✅ Connection successful

5. **Click:** `Apply` → `OK`

#### Method 2: Configuration File

Edit the IDE configuration directly:

**IntelliJ IDEA:**
```bash
# Linux/macOS
nano ~/.config/JetBrains/IntelliJIdea2024.3/options/other.xml

# Windows
notepad %APPDATA%\JetBrains\IntelliJIdea2024.3\options\other.xml
```

**PyCharm:**
```bash
# Linux/macOS
nano ~/.config/JetBrains/PyCharm2024.3/options/other.xml
```

Add this configuration:

```xml
<application>
  <component name="HttpConfigurable">
    <option name="USE_HTTP_PROXY" value="true" />
    <option name="USE_PROXY_PAC" value="false" />
    <option name="PROXY_TYPE_IS_SOCKS" value="true" />
    <option name="PROXY_HOST" value="10.200.200.2" />
    <option name="PROXY_PORT" value="1081" />
    <option name="PROXY_AUTHENTICATION" value="false" />
  </component>
</application>
```

Restart the IDE.

#### Method 3: Launch with JVM Options

Add SOCKS proxy to JVM options:

1. **Open Help menu:**
   - `Help` → `Edit Custom VM Options`

2. **Add these lines:**
   ```
   -Djava.net.useSystemProxies=false
   -DsocksProxyHost=10.200.200.2
   -DsocksProxyPort=1081
   ```

3. **Restart IDE**

### Per-Project Launcher Scripts

**IntelliJ IDEA:**
```bash
cat > ~/launch-idea-vpn.sh <<'EOF'
#!/bin/bash
idea.sh --proxy-server="socks5://10.200.200.2:1081" "$@"
EOF
chmod +x ~/launch-idea-vpn.sh
```

**PyCharm:**
```bash
cat > ~/launch-pycharm-vpn.sh <<'EOF'
#!/bin/bash
pycharm.sh --proxy-server="socks5://10.200.200.2:1081" "$@"
EOF
chmod +x ~/launch-pycharm-vpn.sh
```

**WebStorm:**
```bash
cat > ~/launch-webstorm-vpn.sh <<'EOF'
#!/bin/bash
webstorm.sh --proxy-server="socks5://10.200.200.2:1081" "$@"
EOF
chmod +x ~/launch-webstorm-vpn.sh
```

### Verify JetBrains IDE is Using Proxy

1. **Check in IDE:**
   - Go to: `File` → `Settings` → `Appearance & Behavior` → `System Settings` → `HTTP Proxy`
   - Click: `Check connection`
   - Test URL: `https://plugins.jetbrains.com`

2. **Check Connection via Tools:**
   - Open: `Tools` → `HTTP Client` → `Test RESTful Web Service`
   - Try: `https://api.ipify.org`
   - Should show VPN IP

3. **Check in Terminal:**
   - Open built-in terminal in IDE
   - Run: `curl https://api.ipify.org`
   - Should show VPN IP (if curl respects proxy)

### Special Configurations

#### Git Integration in JetBrains

JetBrains uses system Git. Configure Git separately (see Git section below).

#### Maven/Gradle Proxy

If using Maven or Gradle, configure separately:

**Maven (`~/.m2/settings.xml`):**
```xml
<proxies>
  <proxy>
    <id>socks-proxy</id>
    <active>true</active>
    <protocol>socks</protocol>
    <host>10.200.200.2</host>
    <port>1081</port>
  </proxy>
</proxies>
```

**Gradle (`gradle.properties`):**
```properties
systemProp.socksProxyHost=10.200.200.2
systemProp.socksProxyPort=1081
```

#### NPM/Yarn Proxy (for Node.js projects)

```bash
npm config set proxy socks5://10.200.200.2:1081
npm config set https-proxy socks5://10.200.200.2:1081

yarn config set proxy socks5://10.200.200.2:1081
yarn config set https-proxy socks5://10.200.200.2:1081
```

---

## Web Browsers

### Firefox

**Manual Configuration:**

1. Open: `Settings` → `General` → `Network Settings` → `Settings`
2. Select: **`Manual proxy configuration`**
3. **SOCKS Host:** `10.200.200.2`
4. **Port:** `1081`
5. Select: **`SOCKS v5`**
6. ✅ Check: **`Proxy DNS when using SOCKS v5`** (prevents DNS leaks)
7. Click: `OK`

**Command Line:**

```bash
firefox --proxy-server="socks5://10.200.200.2:1081"
```

### Chrome/Chromium

```bash
google-chrome --proxy-server="socks5://10.200.200.2:1081"
chromium --proxy-server="socks5://10.200.200.2:1081"
```

**Create launcher:**

```bash
cat > ~/launch-chrome-vpn.sh <<'EOF'
#!/bin/bash
google-chrome --proxy-server="socks5://10.200.200.2:1081" --user-data-dir="$HOME/.config/chrome-vpn" "$@"
EOF
chmod +x ~/launch-chrome-vpn.sh
```

### Brave Browser

```bash
brave --proxy-server="socks5://10.200.200.2:1081"
```

---

## Git

Configure Git to use the SOCKS5 proxy for HTTPS and SSH operations.

### Git over HTTPS

**Global Configuration:**

```bash
git config --global http.proxy socks5://10.200.200.2:1081
git config --global https.proxy socks5://10.200.200.2:1081
```

**Per-Repository:**

```bash
cd /path/to/repo
git config http.proxy socks5://10.200.200.2:1081
git config https.proxy socks5://10.200.200.2:1081
```

**Temporary (single command):**

```bash
git -c http.proxy=socks5://10.200.200.2:1081 clone https://github.com/user/repo.git
```

### Git over SSH

For SSH-based Git operations, configure SSH to use the proxy:

**Edit `~/.ssh/config`:**

```bash
# Add this to ~/.ssh/config
Host github.com
    User git
    ProxyCommand nc -x 10.200.200.2:1081 %h %p

Host gitlab.com
    User git
    ProxyCommand nc -x 10.200.200.2:1081 %h %p

Host bitbucket.org
    User git
    ProxyCommand nc -x 10.200.200.2:1081 %h %p
```

**If `nc` doesn't support `-x`, use `socat`:**

```bash
Host github.com
    User git
    ProxyCommand socat - SOCKS5:10.200.200.2:%h:%p,socksport=1081
```

**Or use `ncat` (from nmap):**

```bash
Host github.com
    User git
    ProxyCommand ncat --proxy 10.200.200.2:1081 --proxy-type socks5 %h %p
```

### Remove Git Proxy Configuration

```bash
git config --global --unset http.proxy
git config --global --unset https.proxy
```

### Verify Git is Using Proxy

```bash
# Check configuration
git config --get http.proxy

# Test clone
git clone https://github.com/torvalds/linux.git /tmp/test-clone

# Should work through VPN
```

---

## Terminal Applications

### cURL

```bash
# Single request
curl --socks5-hostname 10.200.200.2:1081 https://api.github.com

# Or use environment variable
export ALL_PROXY=socks5://10.200.200.2:1081
curl https://api.github.com
```

### wget

```bash
# Using environment variable
export all_proxy=socks5://10.200.200.2:1081
wget https://example.com

# Or in ~/.wgetrc
echo "use_proxy = on" >> ~/.wgetrc
echo "http_proxy = socks5://10.200.200.2:1081" >> ~/.wgetrc
echo "https_proxy = socks5://10.200.200.2:1081" >> ~/.wgetrc
```

### SSH

```bash
# Direct command
ssh -o ProxyCommand="nc -x 10.200.200.2:1081 %h %p" user@remote.server

# Or in ~/.ssh/config (as shown in Git section)
```

### Telnet/Netcat

```bash
# Using socat
socat - SOCKS5:10.200.200.2:remote.host:22,socksport=1081
```

---

## Docker

### Configure Docker Daemon

**Edit `/etc/docker/daemon.json`:**

```json
{
  "proxies": {
    "default": {
      "httpProxy": "socks5://10.200.200.2:1081",
      "httpsProxy": "socks5://10.200.200.2:1081"
    }
  }
}
```

**Restart Docker:**

```bash
sudo systemctl restart docker
```

### Configure Docker Client

**For current shell:**

```bash
export HTTP_PROXY=socks5://10.200.200.2:1081
export HTTPS_PROXY=socks5://10.200.200.2:1081
docker pull ubuntu
```

### Docker Build with Proxy

```bash
docker build \
  --build-arg HTTP_PROXY=socks5://10.200.200.2:1081 \
  --build-arg HTTPS_PROXY=socks5://10.200.200.2:1081 \
  -t myimage .
```

---

## Other Applications

### Sublime Text

**Via Package Control Settings:**

```json
// Preferences → Package Settings → Package Control → Settings - User
{
  "http_proxy": "socks5://10.200.200.2:1081",
  "https_proxy": "socks5://10.200.200.2:1081"
}
```

### Atom Editor

**Edit `~/.atom/config.cson`:**

```cson
"*":
  core:
    useProxy: true
    httpProxy: "socks5://10.200.200.2:1081"
```

### Slack

```bash
# Linux
slack --proxy-server="socks5://10.200.200.2:1081"

# Set environment variable
export HTTPS_PROXY=socks5://10.200.200.2:1081
slack
```

### Discord

```bash
discord --proxy-server="socks5://10.200.200.2:1081"
```

### Postman

1. Open: `Settings` → `Proxy`
2. Select: **`Add a custom proxy configuration`**
3. **Proxy Type:** `SOCKS5`
4. **Proxy Server:** `10.200.200.2:1081`
5. Click: `Save`

### Insomnia

1. Open: `Preferences` → `Network`
2. Enable: **`Use system proxy`**
3. Or set environment variable before launching:
   ```bash
   export ALL_PROXY=socks5://10.200.200.2:1081
   insomnia
   ```

---

## System-Wide Proxy Configuration

### GNOME (Ubuntu, Fedora with GNOME)

**GUI:**

1. Open: `Settings` → `Network` → `Network Proxy`
2. Select: **`Manual`**
3. **Socks Host:** `10.200.200.2`
4. **Port:** `1081`
5. Click: `Apply`

**Command Line:**

```bash
gsettings set org.gnome.system.proxy mode 'manual'
gsettings set org.gnome.system.proxy.socks host '10.200.200.2'
gsettings set org.gnome.system.proxy.socks port 1081
```

**Revert:**

```bash
gsettings set org.gnome.system.proxy mode 'none'
```

### KDE Plasma

1. Open: `System Settings` → `Network` → `Proxy`
2. Select: **`Manually specify the proxy settings`**
3. **SOCKS proxy:** `10.200.200.2:1081`
4. Click: `Apply`

### macOS

1. Open: `System Preferences` → `Network`
2. Select your network interface
3. Click: `Advanced` → `Proxies`
4. ✅ Check: **`SOCKS Proxy`**
5. **SOCKS Proxy Server:** `10.200.200.2:1081`
6. Click: `OK` → `Apply`

### Windows

1. Open: `Settings` → `Network & Internet` → `Proxy`
2. Under **Manual proxy setup:**
3. Toggle: **`Use a proxy server`** ON
4. **Address:** `10.200.200.2`
5. **Port:** `1081`
6. Click: `Save`

**Note:** Windows doesn't have native SOCKS5 proxy UI. Use application-specific configurations.

---

## Environment Variables (Universal Method)

Many applications respect these environment variables:

```bash
# Add to ~/.bashrc, ~/.zshrc, or current session
export ALL_PROXY=socks5://10.200.200.2:1081
export all_proxy=socks5://10.200.200.2:1081
export HTTP_PROXY=socks5://10.200.200.2:1081
export HTTPS_PROXY=socks5://10.200.200.2:1081
export http_proxy=socks5://10.200.200.2:1081
export https_proxy=socks5://10.200.200.2:1081

# Exclusions (don't proxy localhost)
export NO_PROXY=localhost,127.0.0.1,::1
export no_proxy=localhost,127.0.0.1,::1
```

**Create a proxy enable/disable script:**

```bash
# ~/enable-vpn-proxy.sh
cat > ~/enable-vpn-proxy.sh <<'EOF'
#!/bin/bash
export ALL_PROXY=socks5://10.200.200.2:1081
export HTTP_PROXY=socks5://10.200.200.2:1081
export HTTPS_PROXY=socks5://10.200.200.2:1081
export NO_PROXY=localhost,127.0.0.1,::1
echo "✓ VPN proxy enabled"
echo "  Proxy: $ALL_PROXY"
EOF

# ~/disable-vpn-proxy.sh
cat > ~/disable-vpn-proxy.sh <<'EOF'
#!/bin/bash
unset ALL_PROXY
unset HTTP_PROXY
unset HTTPS_PROXY
unset all_proxy
unset http_proxy
unset https_proxy
unset NO_PROXY
unset no_proxy
echo "✓ VPN proxy disabled"
EOF

chmod +x ~/enable-vpn-proxy.sh ~/disable-vpn-proxy.sh
```

**Usage:**

```bash
# Enable proxy for current shell
source ~/enable-vpn-proxy.sh

# Disable proxy for current shell
source ~/disable-vpn-proxy.sh
```

---

## Troubleshooting Application Proxy Issues

### Issue: Application Not Using Proxy

**Check 1: Verify proxy is running**
```bash
curl --socks5-hostname 10.200.200.2:1081 https://api.ipify.org
# Should show VPN IP
```

**Check 2: Try localhost instead**
```bash
# Some apps prefer 127.0.0.1
curl --socks5-hostname 127.0.0.1:1081 https://api.ipify.org
```

**Check 3: Check port forwarding**
```bash
sudo netstat -tunapl | grep 1081
# Should show socat listening
```

### Issue: DNS Leaks

**Solution:** Use `--socks5-hostname` instead of `--socks5`

```bash
# BAD - resolves DNS locally
curl --socks5 10.200.200.2:1081 https://example.com

# GOOD - resolves DNS through SOCKS5
curl --socks5-hostname 10.200.200.2:1081 https://example.com
```

### Issue: Some Sites Don't Work

**Possible causes:**
1. Site blocks VPN IPs
2. Site requires specific headers
3. SSL/TLS certificate verification

**Solutions:**
```bash
# Disable SSL verification (CAUTION: Only for testing)
curl --socks5-hostname 10.200.200.2:1081 --insecure https://example.com

# Add custom headers
curl --socks5-hostname 10.200.200.2:1081 -H "User-Agent: Mozilla/5.0" https://example.com
```

### Issue: Slow Performance

**Diagnosis:**
```bash
# Test speed through proxy
time curl --socks5-hostname 10.200.200.2:1081 -o /dev/null https://speed.cloudflare.com/__down?bytes=10000000

# Compare with direct connection
time curl -o /dev/null https://speed.cloudflare.com/__down?bytes=10000000
```

**Solutions:**
- Use closer VPN server
- Check network congestion
- Verify no packet loss

---

## Quick Reference

| Application | Configuration Method | Example |
|------------|---------------------|---------|
| **VSCode** | Command line | `code --proxy-server="socks5://10.200.200.2:1081"` |
| **IntelliJ IDEA** | Settings GUI | `Settings` → `HTTP Proxy` → Manual SOCKS |
| **PyCharm** | Settings GUI | `Settings` → `HTTP Proxy` → Manual SOCKS |
| **Firefox** | Settings | `Network Settings` → Manual → SOCKS v5 |
| **Chrome** | Command line | `chrome --proxy-server="socks5://10.200.200.2:1081"` |
| **Git (HTTPS)** | Config | `git config --global http.proxy socks5://10.200.200.2:1081` |
| **Git (SSH)** | SSH config | `ProxyCommand nc -x 10.200.200.2:1081 %h %p` |
| **cURL** | Command line | `curl --socks5-hostname 10.200.200.2:1081 <url>` |
| **Docker** | Config file | `/etc/docker/daemon.json` |
| **Environment** | Shell | `export ALL_PROXY=socks5://10.200.200.2:1081` |

---

## Best Practices

1. **Use hostname resolution through proxy:** Always use `--socks5-hostname` or equivalent to prevent DNS leaks
2. **Per-application configuration:** Better than system-wide to avoid breaking local apps
3. **Test after configuration:** Verify using `curl https://api.ipify.org`
4. **Document your setup:** Keep notes on which apps use proxy
5. **Disable when not needed:** Don't leave proxy enabled for all apps permanently
6. **Use launcher scripts:** Create convenience scripts for frequently used apps
7. **Check for leaks:** Regularly verify IP and DNS aren't leaking

---

## Additional Resources

- [Main README](README.md) - Project overview
- [QUICKSTART.md](QUICKSTART.md) - Fast setup guide
- [TESTING.md](TESTING.md) - Testing procedures
- [SECURITY.md](SECURITY.md) - Security best practices

For issues or questions, please see [CONTRIBUTING.md](CONTRIBUTING.md).
