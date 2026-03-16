# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2026-03-16

### Added
- **CLI Options**: `--help`, `--version`, `--verbose`, `--quiet` flags
- **CLI Options**: `--interval`, `--cooldown`, `--container`, `--compose-file`
- **CLI Options**: `--monitor-log`, `--restart-log` for custom paths
- **CLI Options**: `--config` for file-based configuration
- **Config File**: Support for `/etc/qwen-monitor/config` and custom paths
- **systemd**: Service unit for Linux server deployments
- **Completions**: Bash and Zsh tab completion scripts
- **Colors**: TTY-safe colored output (auto-disabled in pipes)
- **Signals**: Graceful shutdown on SIGINT/SIGTERM
- **Validation**: Dependency and configuration validation at startup
- **PID File**: Process tracking at `/tmp/qwen-monitor.pid`

### Changed
- **Refactor**: Complete rewrite with professional code structure
- **Refactor**: All functions use `local` keyword for variables
- **Refactor**: Organized functions into labeled sections
- **Improve**: Error messages now actionable and detailed
- **Improve**: Verbose logging for debugging

### Technical Details
- Added `set -euo pipefail` for strict error handling
- Added color initialization with `tput` for portability
- Added `check_dependencies()` for Docker verification
- Added `validate_config()` for configuration sanity checks
- Added `cleanup()` function for graceful shutdown

## [0.1.1] - 2026-03-15

### Added
- **Installer**: `quickinstall.sh` - One-line installation script

## [0.1.0] - 2026-03-15

### Added
- **Core**: `auto-restart-qwen.sh` - Automatic restart script for CLIProxyAPI when Qwen quota errors detected
- **Scripts**: `test-qwen-quota.sh` - Test script for sending multiple requests through CLIProxyAPI
- **Scripts**: `test-qwen-direct.sh` - Test script for direct Qwen API quota testing
- **Docs**: README with installation and usage instructions
- **Docs**: CONTRIBUTING guide with GitFlow workflow
- **Docs**: CHANGELOG following Keep a Changelog format
- **CI**: GitHub Actions workflow for linting bash scripts
- **CI**: Issue templates for bug reports and feature requests

### Technical Details
- Monitor interval: 2 seconds between checks
- Restart cooldown: 10 seconds between restarts
- Error patterns detected: `qwen quota exceeded`, `cooling down`, `Suspended client.*quota`
- Uses `docker compose restart` for reliable container restart
- Logs to `/tmp/cliproxyapi-monitor.log` and `/tmp/cliproxyapi-restarts.log`

[Unreleased]: https://github.com/cativo23/cliproxy-qwen-monitor/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/cativo23/cliproxy-qwen-monitor/releases/tag/v0.2.0
[0.1.1]: https://github.com/cativo23/cliproxy-qwen-monitor/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/cativo23/cliproxy-qwen-monitor/releases/tag/v0.1.0
