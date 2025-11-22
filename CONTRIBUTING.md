# Contributing to VSCode SOCKS5 VPN Namespace

Thank you for your interest in contributing! This project helps developers in countries with internet filtering maintain isolated VPN connections for VSCode.

## How to Contribute

### Reporting Issues

If you encounter a problem:

1. **Check existing issues** to see if it's already reported
2. **Gather information:**
   - Your OS and version
   - Error messages or logs
   - Steps to reproduce
3. **Create a detailed issue** with:
   - Clear title
   - Description of the problem
   - Expected vs actual behavior
   - System information
   - Relevant logs

### Suggesting Features

We welcome feature suggestions! Please:

1. Check if the feature is already requested
2. Explain the use case clearly
3. Describe the expected behavior
4. Consider platform compatibility

### Code Contributions

#### Adding Support for New Distributions

To add support for a new Linux distribution:

1. **Create distribution directory:**
   ```bash
   mkdir -p linux/YourDistro
   ```

2. **Create connect.sh:**
   - Copy from a similar distribution
   - Update package manager commands
   - Update package names
   - Test thoroughly

3. **Create disconnect.sh:**
   - Can usually symlink to base script
   - Or copy from similar distribution

4. **Create README.md:**
   - Document installation steps
   - List required packages
   - Include troubleshooting tips
   - Note distribution-specific considerations

5. **Test on the actual distribution**

#### Improving Existing Scripts

When improving scripts:

1. **Maintain compatibility** with existing configurations
2. **Add comments** explaining complex logic
3. **Use consistent formatting** (2 spaces for indentation)
4. **Test thoroughly** before submitting
5. **Update documentation** if behavior changes

#### Code Style

**Bash Scripts:**
```bash
#!/bin/bash
# Clear header comment explaining the script

set -e  # Exit on error

# Color codes at top
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Functions use snake_case
function check_dependencies() {
    # Function implementation
}

# Variables use UPPER_CASE for constants, lower_case for local
CONST_VALUE="constant"
local_var="variable"
```

**PowerShell Scripts:**
```powershell
# Clear header comment
#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

# Functions use PascalCase
function Test-Dependencies {
    # Function implementation
}

# Variables use $camelCase
$socksPort = 1080
```

### Documentation Contributions

Documentation improvements are always welcome:

- Fix typos or clarify instructions
- Add troubleshooting tips
- Improve examples
- Translate to other languages (future)

### Testing

Before submitting a pull request:

1. **Test the happy path** (normal operation)
2. **Test error cases** (missing dependencies, wrong config, etc.)
3. **Test cleanup** (ensure disconnect works properly)
4. **Verify no leftover processes or configurations**

### Pull Request Process

1. **Fork the repository**
2. **Create a feature branch:**
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Make your changes**
4. **Test thoroughly**
5. **Commit with clear messages:**
   ```
   Add support for Debian 12
   
   - Create Debian-specific scripts
   - Add package installation guide
   - Include troubleshooting section
   ```
6. **Push to your fork:**
   ```bash
   git push origin feature/your-feature-name
   ```
7. **Open a pull request** with:
   - Clear description of changes
   - Why the change is needed
   - Testing performed
   - Any breaking changes

### Code Review

All submissions require review. We'll:

- Check code quality
- Verify functionality
- Test on target platforms
- Provide constructive feedback

Please be patient and responsive to feedback!

## Development Setup

### Prerequisites

For testing Linux scripts:
- Linux VM or physical machine
- sudo access
- OpenVPN config file for testing

For testing macOS scripts:
- macOS machine
- Homebrew installed

For testing Windows scripts:
- Windows 10/11 with WSL2
- PowerShell with admin privileges

### Local Testing

1. **Clone your fork:**
   ```bash
   git clone https://github.com/YOUR-USERNAME/dev-socks-isolation.git
   cd dev-socks-isolation
   ```

2. **Make your changes**

3. **Test scripts:**
   ```bash
   cd linux/YourDistro
   ./connect.sh
   # Verify functionality
   ./disconnect.sh
   # Verify cleanup
   ```

4. **Check for leftover resources:**
   ```bash
   # Linux
   sudo ip netns list
   ip link show
   sudo iptables -L
   
   # Processes
   ps aux | grep -E "openvpn|sockd|socat"
   ```

## Areas Needing Help

### High Priority

- [ ] Testing on more Linux distributions
- [ ] Improved error messages
- [ ] Automatic recovery from common errors
- [ ] Better Windows native solution (without WSL2)

### Medium Priority

- [ ] GUI application wrapper
- [ ] systemd service templates
- [ ] Automated tests
- [ ] Performance optimizations

### Low Priority

- [ ] Support for other VPN protocols (WireGuard, etc.)
- [ ] Web-based configuration interface
- [ ] Mobile documentation

## Community

### Be Respectful

- Use welcoming and inclusive language
- Respect differing viewpoints
- Accept constructive criticism gracefully
- Focus on what's best for the community

### Get Help

- Open an issue for questions
- Use GitHub Discussions for general discussion
- Tag issues appropriately

## Recognition

Contributors will be:
- Listed in CONTRIBUTORS.md (coming soon)
- Mentioned in release notes
- Appreciated by the community!

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

## Questions?

Feel free to open an issue or discussion if you have any questions about contributing!

---

Thank you for making this project better! 🎉
