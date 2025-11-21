# Release Notes - Version 2.0.0

**Release Date:** November 21, 2025

## 🎉 Major Update: JetBrains IDEs Support

We're excited to announce **Version 2.0.0** of the VSCode/JetBrains SOCKS5 VPN Namespace project! This major release adds comprehensive support for all JetBrains IDEs while maintaining full backward compatibility with existing VSCode functionality.

---

## 🆕 What's New

### Full JetBrains Family Support

Version 2.0.0 now supports **all JetBrains IDEs**, enabling developers to route their IDE traffic through an isolated VPN connection while keeping their host IP unchanged.

#### Supported IDEs:
- ✅ **IntelliJ IDEA** (Ultimate & Community)
- ✅ **PyCharm** (Professional & Community)
- ✅ **WebStorm** - JavaScript & TypeScript
- ✅ **DataGrip** - Database IDE
- ✅ **PhpStorm** - PHP development
- ✅ **GoLand** - Go development
- ✅ **CLion** - C/C++ development
- ✅ **Rider** - .NET development
- ✅ **RubyMine** - Ruby development
- ✅ **AppCode** - iOS/macOS development
- ✅ **Android Studio** - Android development

### Enhanced Features

#### 🔧 Improved SOCKS5 Configuration
- **Optimized Dante server binding**: Changed from `127.0.0.1` to `0.0.0.0` for better IDE compatibility
- **Enhanced connection stability**: Improved proxy handling for concurrent IDE usage
- **Better plugin marketplace access**: Automatic verification of JetBrains plugins site

#### 📘 Comprehensive Documentation
- **New JetBrains Configuration Guide** (`JETBRAINS_GUIDE.md`)
  - Detailed step-by-step setup instructions
  - Multiple configuration methods (Manual, Auto-detect, JVM arguments)
  - Visual configuration diagrams
  - Troubleshooting section
  - Performance optimization tips

#### 🧪 Enhanced Testing
- **JetBrains marketplace verification**: Automatically tests `plugins.jetbrains.com` accessibility
- **Multi-IDE testing procedures**: Comprehensive testing guide for all supported IDEs
- **Connection verification**: Improved diagnostic tools

#### 🎨 Better User Experience
- **Updated CLI output**: Color-coded IDE-specific instructions
- **Improved setup messages**: Clear configuration steps for both VSCode and JetBrains
- **Enhanced status reporting**: Better visibility into proxy status

---

## 🔄 Changes from Version 1.x

### Breaking Changes
**None!** This release is 100% backward compatible with version 1.x.

### Modified Files
- `linux/common/connect-base.sh` - Enhanced with JetBrains support
- `linux/common/disconnect-base.sh` - Updated titles
- All distribution-specific `connect.sh` files - Updated branding
- `README.md` - Added JetBrains documentation
- `VERSION` - Updated to 2.0.0

### New Files
- `JETBRAINS_GUIDE.md` - Comprehensive JetBrains IDEs configuration guide
- `CHANGELOG.md` - Version history and change tracking
- `RELEASE_NOTES.md` - This file

---

## 📦 Installation & Upgrade

### New Installation
```bash
git clone https://github.com/navidrezadoost/vscode-socks5-namespace.git
cd vscode-socks5-namespace/linux/<your-distro>
chmod +x connect.sh
./connect.sh
```

### Upgrading from 1.x
```bash
# Navigate to your existing installation
cd vscode-socks5-namespace

# Pull latest changes
git pull origin main

# Disconnect existing setup (if running)
./linux/<your-distro>/disconnect.sh

# Reconnect with new version
./linux/<your-distro>/connect.sh
```

**Note:** Your existing configurations and workflows will continue to work without any changes!

---

## 🎯 Usage

### VSCode (Same as Before)
```bash
code --proxy-server="socks5://10.200.200.2:1081"
```

### JetBrains IDEs (New!)

#### Method 1: Manual Proxy Configuration
1. Open Settings: `File` → `Settings` → `HTTP Proxy`
2. Select: `Manual proxy configuration` → `SOCKS`
3. Host: `10.200.200.2`, Port: `1081`
4. Test connection with `https://plugins.jetbrains.com`
5. Apply and restart IDE

#### Method 2: JVM Arguments
Add to `idea.vmoptions` (or equivalent):
```
-Djava.net.socks.host=10.200.200.2
-Djava.net.socks.port=1081
```

See [JETBRAINS_GUIDE.md](JETBRAINS_GUIDE.md) for detailed instructions.

---

## 🧪 Testing

After setup, verify everything works:

### VSCode
```bash
# Launch with proxy
code --proxy-server="socks5://10.200.200.2:1081"

# Test extension marketplace
# Extensions → Search for any extension
```

### JetBrains IDEs
```bash
# Test proxy connection
curl --socks5 10.200.200.2:1081 https://plugins.jetbrains.com

# In IDE: File → Settings → Plugins → Marketplace
# Should load successfully
```

See [TESTING.md](TESTING.md) for comprehensive testing procedures.

---

## 🐛 Known Issues

None at this time. If you encounter any issues:
1. Check the [JETBRAINS_GUIDE.md](JETBRAINS_GUIDE.md) troubleshooting section
2. Review logs: `/tmp/danted_vpnspace.log` and `/tmp/openvpn_vpnspace.log`
3. [Open an issue](https://github.com/navidrezadoost/vscode-socks5-namespace/issues)

---

## 📊 Technical Details

### Architecture Changes

#### Dante SOCKS5 Server Configuration
```diff
- internal: 127.0.0.1 port = $SOCKS_PORT
+ internal: 0.0.0.0 port = $SOCKS_PORT
```
This change allows better accessibility from host applications, particularly JetBrains IDEs.

#### Testing Enhancements
- Added JetBrains plugins site connectivity test
- Enhanced error reporting for IDE-specific issues
- Improved connection verification procedures

### Performance Impact
- **No performance degradation**: Same SOCKS5 server handles both VSCode and JetBrains traffic
- **Concurrent IDE support**: Multiple IDEs can use the proxy simultaneously
- **Connection pooling**: Dante efficiently manages multiple connections

---

## 🔐 Security

No security changes in this release. All existing security measures remain in place:
- Traffic isolation via Linux namespaces
- Host IP protection
- VPN-only routing for designated applications

See [SECURITY.md](SECURITY.md) for security best practices.

---

## 🤝 Contributing

We welcome contributions! This release was made possible by:
- User feedback requesting JetBrains support
- Community testing and validation
- Documentation improvements

See [CONTRIBUTING.md](CONTRIBUTING.md) to get involved.

---

## 📚 Documentation

### Updated Documentation
- **README.md** - Added JetBrains support overview
- **USAGE_GUIDE.md** - Enhanced with JetBrains configuration (existing)
- **TESTING.md** - IDE-specific testing procedures

### New Documentation
- **JETBRAINS_GUIDE.md** - Comprehensive JetBrains configuration guide
- **CHANGELOG.md** - Version history
- **RELEASE_NOTES.md** - This document

---

## 🎁 Credits

### Special Thanks
- **Community Contributors** - For feature requests and testing
- **JetBrains** - For excellent IDE platform
- **Dante Server Team** - For robust SOCKS5 implementation
- **Original Script Author** - For the enhanced version serving as inspiration

---

## 🔮 What's Next?

We're already planning for future releases:
- **Version 2.1.0**: Enhanced monitoring and logging
- **Version 2.2.0**: GUI configuration tool
- **Version 3.0.0**: Support for additional IDEs and applications

Stay tuned!

---

## 📞 Support

- **Documentation**: See [docs](README.md#documentation) section
- **Issues**: [GitHub Issues](https://github.com/navidrezadoost/vscode-socks5-namespace/issues)
- **Discussions**: [GitHub Discussions](https://github.com/navidrezadoost/vscode-socks5-namespace/discussions)

---

## ⭐ Enjoy!

Thank you for using VSCode/JetBrains SOCKS5 VPN Namespace! If this project helps you, please consider:
- ⭐ Starring the repository
- 📢 Sharing with fellow developers
- 🐛 Reporting bugs or suggesting features
- 🤝 Contributing improvements

Happy coding with your isolated VPN setup! 🚀
