# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2025-11-21

### 🎉 Major Features

#### Added JetBrains IDEs Full Support
- **Complete JetBrains family support**: IntelliJ IDEA, PyCharm, WebStorm, DataGrip, PhpStorm, GoLand, CLion, Rider, and all other JetBrains IDEs
- **Enhanced SOCKS5 configuration**: Optimized Dante server to bind on `0.0.0.0` instead of `127.0.0.1` for better compatibility with JetBrains IDEs
- **Comprehensive IDE configuration guide**: Added detailed setup instructions for JetBrains IDEs with multiple configuration methods
- **JetBrains plugins verification**: Added automatic testing of `plugins.jetbrains.com` accessibility through the proxy
- **Multi-IDE architecture**: Both VSCode and JetBrains IDEs can now use the same isolated VPN connection simultaneously

### 🔧 Improvements

#### Enhanced Proxy Stability
- **Robust SOCKS5 binding**: Changed internal SOCKS5 server binding from `127.0.0.1` to `0.0.0.0` for improved accessibility
- **Better error handling**: Added verification step specifically for JetBrains services
- **Connection testing**: Comprehensive testing of both VSCode marketplace and JetBrains plugins site

#### Documentation Updates
- **Updated project title**: Renamed from "VSCode SOCKS5 Namespace" to "VSCode/JetBrains SOCKS5 Namespace"
- **Enhanced setup instructions**: Added detailed JetBrains IDE configuration steps
- **Multiple configuration methods**: Documented manual SOCKS, auto-detect, and JVM arguments methods
- **Improved CLI output**: Added color-coded sections for different IDEs in setup completion message

### 🐛 Bug Fixes
- Fixed SOCKS5 proxy accessibility issues with JetBrains IDEs
- Improved connection stability for IDE plugin marketplaces
- Enhanced namespace isolation for concurrent IDE usage

### 📚 Documentation
- Updated README.md with JetBrains support information
- Enhanced usage instructions for all supported IDEs
- Added troubleshooting section for IDE-specific issues

### ⚙️ Technical Details
- Modified `connect-base.sh` Dante configuration to use `0.0.0.0` binding
- Added JetBrains marketplace connectivity verification
- Improved proxy testing procedures
- Enhanced status output with IDE-specific instructions

---

## [1.0.0] - Initial Release

### Added
- Initial release with VSCode support
- Linux namespace isolation for VPN
- SOCKS5 proxy setup with Dante
- OpenVPN integration
- Support for multiple Linux distributions (Arch, Ubuntu, Fedora, etc.)
- macOS support with limited isolation
- Windows WSL2 support
- Interactive configuration
- Auto-detection of network interfaces
- Dependency checking and installation
- Comprehensive documentation
- Testing procedures
- Security guidelines

---

## Version Notes

### Version 2.0.0 Breaking Changes
None - This is a backwards-compatible enhancement that adds JetBrains support while maintaining all existing VSCode functionality.

### Upgrade Instructions
If you're upgrading from version 1.x:
1. Pull the latest changes from the repository
2. Run the disconnect script to clean up existing setup
3. Run the connect script again with the new version
4. Configure your JetBrains IDEs using the new instructions

### Compatibility
- **Maintained**: All VSCode functionality from v1.x
- **Added**: Full JetBrains IDEs support
- **Compatible with**: All previously supported Linux distributions, macOS, and Windows WSL2
