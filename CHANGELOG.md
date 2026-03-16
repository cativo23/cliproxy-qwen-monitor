# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial release with auto-restart functionality for Qwen quota errors
- Monitor script for detecting Qwen quota exceeded errors
- Test scripts for quota testing (direct API and proxy)

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

[Unreleased]: https://github.com/cativo23/cliproxy-qwen-monitor/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/cativo23/cliproxy-qwen-monitor/releases/tag/v0.1.0
