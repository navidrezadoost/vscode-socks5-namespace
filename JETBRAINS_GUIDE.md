# JetBrains IDEs Configuration Guide

This guide provides detailed instructions for configuring JetBrains IDEs (IntelliJ IDEA, PyCharm, WebStorm, DataGrip, etc.) to use the isolated VPN SOCKS5 proxy.

## 🎯 Supported JetBrains IDEs

All JetBrains IDEs are supported, including but not limited to:
- IntelliJ IDEA (Ultimate & Community)
- PyCharm (Professional & Community)
- WebStorm
- DataGrip
- PhpStorm
- GoLand
- CLion
- Rider
- RubyMine
- AppCode
- Android Studio

## 🚀 Quick Setup

After running the connect script, you'll see the proxy address:
```
SOCKS5 Address: socks5://10.200.200.2:1081
```

Follow one of the methods below to configure your IDE.

---

## 📝 Configuration Methods

### Method 1: Manual SOCKS Proxy (Recommended) ⭐

This is the most reliable method for JetBrains IDEs.

#### Step-by-Step Instructions:

1. **Open Settings/Preferences**
   - Windows/Linux: `File` → `Settings` (or `Ctrl+Alt+S`)
   - macOS: `IntelliJ IDEA` → `Preferences` (or `Cmd+,`)

2. **Navigate to Proxy Settings**
   ```
   Appearance & Behavior → System Settings → HTTP Proxy
   ```

3. **Configure Manual Proxy**
   - Select: `Manual proxy configuration`
   - Select: `SOCKS` (important: not HTTP/HTTPS)
   
4. **Enter Proxy Details**
   ```
   Host name: 10.200.200.2
   Port number: 1081
   ```
   
   ✅ **Check**: SOCKS Proxy checkbox  
   ❌ **Uncheck**: No proxy for (unless you have specific requirements)

5. **Test Connection**
   - Click `Check connection` button
   - Test URL: `https://plugins.jetbrains.com`
   - You should see: ✅ Connection successful

6. **Apply and Restart**
   - Click `Apply` → `OK`
   - Restart your IDE for changes to take full effect

#### Visual Guide:

```
┌─────────────────────────────────────────────────┐
│ HTTP Proxy                                      │
├─────────────────────────────────────────────────┤
│ ○ No proxy                                      │
│ ○ Auto-detect proxy settings                   │
│ ● Manual proxy configuration                   │
│                                                 │
│   ○ HTTP    ○ HTTPS    ● SOCKS                │
│                                                 │
│   Host name: [10.200.200.2        ]           │
│   Port number: [1081              ]           │
│                                                 │
│   ☑ SOCKS Proxy                                │
│                                                 │
│   [Check connection...]                        │
│                                                 │
│                    [Apply] [OK] [Cancel]       │
└─────────────────────────────────────────────────┘
```

---

### Method 2: Auto-detect Proxy Settings

This method sometimes works automatically but is less reliable.

1. Open Settings: `File` → `Settings` → `HTTP Proxy`
2. Select: `Auto-detect proxy settings`
3. Click `Apply` → `OK`
4. Test by accessing: `File` → `Settings` → `Plugins` → `Marketplace`

⚠️ **Note**: If plugins don't load, switch to Method 1.

---

### Method 3: JVM Arguments (Advanced)

For advanced users or specific scenarios, you can add JVM arguments.

#### Option A: Edit IDE VM Options File

1. **Open VM Options File**
   - `Help` → `Edit Custom VM Options...`
   - This creates/opens `idea.vmoptions` (or `pycharm.vmoptions`, etc.)

2. **Add SOCKS Proxy Arguments**
   ```
   -Djava.net.socks.host=10.200.200.2
   -Djava.net.socks.port=1081
   ```

3. **Save and Restart IDE**

#### Option B: Environment Variable

Set before launching IDE:
```bash
export JAVA_OPTS="-Djava.net.socks.host=10.200.200.2 -Djava.net.socks.port=1081"
idea  # or pycharm, webstorm, etc.
```

---

## 🧪 Testing Your Configuration

### Test 1: Check Proxy Connection

1. Go to `Settings` → `HTTP Proxy`
2. Click `Check connection`
3. Test URL: `https://plugins.jetbrains.com`
4. Expected: ✅ Connection successful

### Test 2: Access Plugin Marketplace

1. Go to `File` → `Settings` → `Plugins`
2. Click `Marketplace` tab
3. Search for any plugin (e.g., "Rainbow Brackets")
4. Plugins should load successfully

### Test 3: Update IDE/Plugins

1. `Help` → `Check for Updates...`
2. Should successfully check JetBrains servers
3. Plugin updates should be available in `Plugins` → `Installed` → `Update All`

### Test 4: Command Line Verification

From terminal:
```bash
# Test proxy directly
curl --socks5 10.200.200.2:1081 https://plugins.jetbrains.com

# Check your public IP through proxy
curl --socks5 10.200.200.2:1081 https://api.ipify.org
```

Expected: Should show your VPN IP, not your real IP.

---

## 🐛 Troubleshooting

### Issue: "Connection Failed" when testing proxy

**Solutions:**
1. Verify VPN namespace is running:
   ```bash
   sudo ip netns list
   # Should show: vpnspace
   ```

2. Check if SOCKS5 server is running:
   ```bash
   sudo ip netns exec vpnspace pgrep sockd
   # Should return a process ID
   ```

3. Test proxy from command line:
   ```bash
   curl --socks5 10.200.200.2:1081 https://api.ipify.org
   ```

4. Check SOCKS5 logs:
   ```bash
   sudo cat /tmp/danted_vpnspace.log
   ```

### Issue: Plugins Don't Load

**Solutions:**
1. Switch from "Auto-detect" to "Manual proxy configuration"
2. Ensure you selected "SOCKS" (not HTTP/HTTPS)
3. Restart IDE after applying settings
4. Clear IDE cache: `File` → `Invalidate Caches / Restart`

### Issue: IDE Freezes When Accessing Internet

**Solutions:**
1. Increase proxy timeout in IDE settings
2. Check VPN connection stability:
   ```bash
   sudo ip netns exec vpnspace ip addr show tun0
   ```
3. Check OpenVPN logs:
   ```bash
   sudo cat /tmp/openvpn_vpnspace.log
   ```

### Issue: Some Features Work, Others Don't

**Solutions:**
1. Check if "No proxy for" field is empty
2. Disable "Use proxy" for specific hosts only if needed
3. Try Method 3 (JVM arguments) as fallback

---

## 🔍 Verification Checklist

Use this checklist to ensure everything is working:

- [ ] VPN namespace is running (`sudo ip netns list`)
- [ ] SOCKS5 server is running inside namespace
- [ ] Proxy accessible from host (`curl --socks5 10.200.200.2:1081 https://api.ipify.org`)
- [ ] JetBrains proxy test succeeds
- [ ] Plugin marketplace loads successfully
- [ ] Can search and install plugins
- [ ] IDE update check works
- [ ] Your real IP is not exposed (verify with ipify.org through IDE)

---

## 💡 Pro Tips

### Tip 1: Per-Project Proxy Settings
You can configure different proxy settings per project:
- Right-click project → `Open Module Settings` → `Proxy`

### Tip 2: Bypass Proxy for Local Servers
Add to "No proxy for":
```
localhost,127.0.0.1,*.local
```

### Tip 3: Multiple IDEs
You can run multiple JetBrains IDEs simultaneously, all using the same VPN proxy!

### Tip 4: Toggle Proxy Easily
Create a macro or use IDE's "Manage Configurations" to switch proxy on/off quickly.

### Tip 5: Monitor Proxy Usage
Check proxy logs in real-time:
```bash
sudo tail -f /tmp/danted_vpnspace.log
```

---

## 📊 Performance Considerations

### Expected Performance
- **Plugin Installation**: Depends on VPN speed
- **IDE Updates**: Same as VPN connection speed
- **Code Intelligence**: No impact (local processing)
- **Local File Operations**: No impact

### Optimization Tips
1. Use a fast VPN server (low latency)
2. Keep VPN connection stable
3. Use wired connection instead of WiFi if possible
4. Close unused IDEs to free up SOCKS5 connections

---

## 🔐 Security Notes

### What's Protected
✅ IDE plugin downloads  
✅ IDE update checks  
✅ Extension marketplace access  
✅ Any IDE internet requests

### What's NOT Protected
❌ Browser traffic (unless configured separately)  
❌ System updates  
❌ Other applications  

This is by design - only your IDE traffic goes through VPN!

---

## 🆘 Getting Help

If you encounter issues:

1. **Check logs:**
   - OpenVPN: `/tmp/openvpn_vpnspace.log`
   - SOCKS5: `/tmp/danted_vpnspace.log`

2. **Test proxy independently:**
   ```bash
   curl -v --socks5 10.200.200.2:1081 https://plugins.jetbrains.com
   ```

3. **Restart everything:**
   ```bash
   # Disconnect
   ./disconnect.sh
   
   # Reconnect
   ./connect.sh
   ```

4. **Check GitHub Issues:**
   - Search for similar problems
   - Open a new issue with logs

---

## 📚 Related Documentation

- [VSCode Configuration](USAGE_GUIDE.md#vscode-configuration)
- [Testing Guide](TESTING.md)
- [Troubleshooting](README.md#troubleshooting)
- [Security Best Practices](SECURITY.md)

---

## ✨ Success Stories

After configuring correctly, you should be able to:
- ✅ Install plugins from JetBrains Marketplace
- ✅ Update your IDE to latest version
- ✅ Access GitHub repositories via IDE
- ✅ Use AI assistants (GitHub Copilot, etc.)
- ✅ Download dependencies through IDE
- ✅ All while your host IP remains unchanged!

---

**Note:** Configuration steps are the same for all JetBrains IDEs. Screenshots show IntelliJ IDEA, but the settings are identical across all products.
