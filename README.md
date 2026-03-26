<div align="center">

```
 ____ _     ___ ____                         _    ____ ___
/ ___| |   |_ _|  _ \ _ __ _____  ___   _   / \  |  _ \_ _|
| |   | |    | || |_) | '__/ _ \ \/ / | | | / _ \ | |_) | |
| |___| |___ | ||  __/| | | (_) >  <| |_| |/ ___ \|  __/| |
\____|_____|___|_|   |_|  \___/_/\_\\__, /_/   \_\_|  |___|
                                    |___/
 ___                       __  __             _ _
/ _ \__      _____ _ __   |  \/  | ___  _ __ (_) |_ ___  _ __
| | | \ \ /\ / / _ \ '_ \  | |\/| |/ _ \| '_ \| | __/ _ \| '__|
| |_| |\ V  V /  __/ | | | | |  | | (_) | | | | | || (_) | |
\__\_\ \_/\_/ \___|_| |_| |_|  |_|\___/|_| |_|_|\__\___/|_|
```

</div>

[![GitHub release](https://img.shields.io/github/v/release/cativo23/cliproxy-qwen-monitor?include_prereleases&style=flat-square)](https://github.com/cativo23/cliproxy-qwen-monitor/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Bash](https://img.shields.io/badge/bash-5.0+-brightgreen.svg)](https://www.gnu.org/software/bash/)
[![Docker](https://img.shields.io/badge/docker-required-blue.svg)](https://www.docker.com/)

## Overview

**Automatic CLIProxyAPI recovery from Qwen quota errors.** This tool monitors CLIProxyAPI logs and automatically restarts the container when it detects Qwen API quota exhaustion, preventing service downtime without manual intervention.

> **Why this exists:** CLIProxyAPI Plus has a bug where reaching the daily quota on one Qwen account blocks **all** accounts in the pool until the container is manually restarted. This monitor automates the recovery process.

## Description

CLIProxyAPI Qwen Monitor is a lightweight bash script that continuously monitors CLIProxyAPI container logs for Qwen-specific quota errors and automatically restarts the container to restore service.

Key features:

- **Continuous monitoring** every 2 seconds
- **Qwen-specific detection** — ignores errors from other providers
- **Automatic restart** with configurable cooldown (default: 10s)
- **Timestamp-aware filtering** — avoids counting stale errors after restart
- **Comprehensive logging** for debugging and audit trails
- **Systemd support** for production deployment

## Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/cativo23/cliproxy-qwen-monitor.git
cd cliproxy-qwen-monitor

# 2. Configure the docker-compose path (IMPORTANT)
cp config/qwen-monitor.conf.example config/qwen-monitor.conf
nano config/qwen-monitor.conf
# Edit COMPOSE_FILE with the absolute path to your docker-compose.local.yml

# 3. Start the monitor (background)
nohup ./scripts/auto-restart-qwen.sh --config config/qwen-monitor.conf &

# 4. Verify it's running
ps aux | grep auto-restart-qwen
tail -f /tmp/cliproxyapi-monitor.log
```

### Stop

```bash
kill $(cat /tmp/qwen-monitor.pid) 2>/dev/null || pkill -f auto-restart-qwen
```

## Usage

```bash
# Default values
./scripts/auto-restart-qwen.sh

# With custom options
./scripts/auto-restart-qwen.sh --interval 5 --cooldown 30 --verbose

# Show help
./scripts/auto-restart-qwen.sh --help
```

### Options

| Option | Description | Default |
|--------|-------------|---------|
| `-i, --interval SECS` | Check interval | 2 |
| `-c, --cooldown SECS` | Cooldown between restarts | 10 |
| `-n, --container NAME` | Container name | cliproxyapi |
| `-f, --compose-file FILE` | Docker Compose file path | `$HOME/cliproxyapi-dashboard/docker-compose.local.yml` |
| `-v, --verbose` | Debug mode | - |
| `-q, --quiet` | Errors only | - |
| `-C, --config FILE` | Load configuration file | - |
| `-h, --help` | Show help | - |

### Configuration File

Optional: `config/qwen-monitor.conf` or `~/.config/qwen-monitor/config`

```bash
CHECK_INTERVAL=2
COOLDOWN_PERIOD=10
CONTAINER_NAME=cliproxyapi
COMPOSE_FILE=/home/user/cliproxyapi-dashboard/docker-compose.local.yml
VERBOSE=false
```

### Configure Docker-Compose Path

**Important:** The script needs the absolute path to the `docker-compose.yml` file from your CLIProxyAPI installation.

**Option 1: Use configuration file (recommended)**

```bash
# 1. Copy and edit the configuration file
cp config/qwen-monitor.conf.example config/qwen-monitor.conf
nano config/qwen-monitor.conf

# 2. Update COMPOSE_FILE with the absolute path
COMPOSE_FILE=/home/user/cliproxyapi-dashboard/docker-compose.local.yml

# 3. Start the monitor with the config
nohup ./scripts/auto-restart-qwen.sh --config config/qwen-monitor.conf &
```

**Option 2: Use command line**

```bash
# Find the docker-compose path
docker inspect cliproxyapi --format '{{.Config.WorkingDir}}'

# Start with absolute path
nohup ./scripts/auto-restart-qwen.sh -f /path/to/docker-compose.local.yml &
```

**If restart fails with "exit code: 1"**, verify the compose file path:
```bash
# Verify the path exists
ls -la /path/to/docker-compose.local.yml

# Test manual restart
docker-compose -f /path/to/docker-compose.local.yml restart cliproxyapi
```

## Scripts

| Script | Description |
|--------|-------------|
| `auto-restart-qwen.sh` | Main monitor script |
| `show-logs.sh` | View logs with colors and stats |
| `test-qwen-quota.sh` | Quota test via proxy |
| `test-qwen-direct.sh` | Direct API quota test |

## Logs

| Log | Location |
|-----|----------|
| Monitor | `/tmp/cliproxyapi-monitor.log` |
| Restarts | `/tmp/cliproxyapi-restarts.log` |
| PID | `/tmp/qwen-monitor.pid` |

### View Logs

```bash
# Real-time
tail -f /tmp/cliproxyapi-monitor.log

# With formatting and stats
./scripts/show-logs.sh

# Restart history
cat /tmp/cliproxyapi-restarts.log
```

## Install as a Service (Linux)

```bash
# 1. Copy systemd service
sudo cp systemd/qwen-monitor.service /etc/systemd/system/

# 2. Adjust paths in the service (important: COMPOSE_FILE)
sudo nano /etc/systemd/system/qwen-monitor.service

# Edit ExecStart to include the compose file path:
# ExecStart=/path/to/auto-restart-qwen.sh --config /path/to/qwen-monitor.conf

# 3. Enable and start
sudo systemctl daemon-reload
sudo systemctl enable --now qwen-monitor

# 4. Check status
sudo systemctl status qwen-monitor
journalctl -u qwen-monitor -f
```

## Requirements

- Docker + Docker Compose plugin
- Bash 5.0+
- CLIProxyAPI Plus running

## Project Structure

```
cliproxy-qwen-monitor/
├── scripts/
│   ├── auto-restart-qwen.sh    # Main monitor
│   ├── show-logs.sh            # Log viewer
│   ├── test-qwen-quota.sh      # Proxy test
│   └── test-qwen-direct.sh     # Direct test
├── config/
│   └── qwen-monitor.conf.example
├── systemd/
│   └── qwen-monitor.service
├── completions/
│   ├── qwen-monitor.bash
│   └── qwen-monitor.zsh
├── README.md
├── CHANGELOG.md
└── LICENSE
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

MIT — see [LICENSE](LICENSE)
