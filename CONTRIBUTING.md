# Contributing to vscode-vpnspace

Thank you for your interest in contributing! This document provides guidelines for contributing to this project.

## How to Contribute

1. **Fork the repository**
2. **Create a feature branch** (`git checkout -b feature/amazing-feature`)
3. **Make your changes**
4. **Test thoroughly** on your system
5. **Commit your changes** (`git commit -m 'Add amazing feature'`)
6. **Push to your branch** (`git push origin feature/amazing-feature`)
7. **Open a Pull Request**

## Development Guidelines

### Code Style

- Use clear, descriptive variable names
- Add comments for complex logic
- Follow existing script structure and formatting
- Use shellcheck to validate bash scripts

### Testing

Before submitting a PR, please test:

1. **Basic functionality**
   - Start the namespace with a valid OpenVPN config
   - Verify the SOCKS5 proxy is accessible
   - Launch VSCode successfully
   - Clean up properly

2. **Error handling**
   - Test with invalid config files
   - Test cleanup with partial setup
   - Test when dependencies are missing

3. **Edge cases**
   - Multiple start attempts without cleanup
   - Cleanup when namespace doesn't exist
   - Different OpenVPN configurations

### Shell Script Best Practices

- Always use `set -e` for start scripts
- Use `set +e` for cleanup scripts (allow partial cleanup)
- Check for required commands before execution
- Provide helpful error messages
- Use colors for better UX (but make them optional)

## Areas for Contribution

### High Priority

- Support for other Linux distributions
- Better error messages and diagnostics
- Improved OpenVPN connection detection
- Support for OpenVPN authentication methods

### Medium Priority

- Configuration file for script settings
- Multiple simultaneous VPN namespaces
- Systemd service integration
- Auto-reconnect on VPN disconnect

### Low Priority

- GUI wrapper
- Browser extensions for easy proxy switching
- macOS support (using different networking approach)
- Windows WSL2 support

## Reporting Bugs

When reporting bugs, please include:

- Linux distribution and version
- Kernel version (`uname -r`)
- OpenVPN version (`openvpn --version`)
- Dante version (`danted -v`)
- Complete error messages or logs
- Steps to reproduce

## Feature Requests

Feature requests are welcome! Please:

- Check existing issues first
- Clearly describe the feature
- Explain the use case
- Consider implementation complexity

## Security

If you discover a security vulnerability:

1. **Do NOT** open a public issue
2. Email the maintainer privately
3. Allow time for a fix before public disclosure

## Code of Conduct

- Be respectful and constructive
- Welcome newcomers
- Focus on the issue, not the person
- Keep discussions professional

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

## Questions?

Feel free to open an issue for any questions about contributing!
