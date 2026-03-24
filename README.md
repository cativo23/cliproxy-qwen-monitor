<div align="center">

**CLIProxyAPI Qwen Monitor**

Automatically restarts CLIProxyAPI when it detects Qwen quota errors.

[![GitHub release](https://img.shields.io/github/v/release/cativo23/cliproxy-qwen-monitor?include_prereleases&style=flat-square)](https://github.com/cativo23/cliproxy-qwen-monitor/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](LICENSE)

</div>

---

## Problem

CLIProxyAPI Plus has a bug: when one Qwen account reaches its daily quota, **all** accounts in the pool get blocked until the container is manually restarted.

## Solution

This script monitors CLIProxyAPI logs and automatically restarts the container when it detects Qwen quota errors.

- **Monitors** every 2 seconds
- **Detects** only Qwen errors (not other providers)
- **Restarts** the container with a 10-second cooldown
- **Logs** all events for debugging

---

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

---

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
| `-v, --verbose` | Debug mode | - |
| `-q, --quiet` | Errors only | - |
| `-h, --help` | Show help | - |

### Configuration File

Optional: `/etc/qwen-monitor/config` or `~/.config/qwen-monitor/config`

```bash
CHECK_INTERVAL=2
COOLDOWN_PERIOD=10
CONTAINER_NAME=cliproxyapi
COMPOSE_FILE=docker-compose.local.yml
VERBOSE=false
```

### Configure Docker-Compose Path

**Important:** The script needs the path to the `docker-compose.yml` file from your CLIProxyAPI installation.

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

---

## Scripts

| Script | Description |
|--------|-------------|
| `auto-restart-qwen.sh` | Main monitor |
| `show-logs.sh` | View logs with colors and stats |
| `test-qwen-quota.sh` | Quota test via proxy |
| `test-qwen-direct.sh` | Direct API quota test |

---

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

---

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

---

## Requirements

- Docker + Docker Compose plugin
- Bash 5.0+
- CLIProxyAPI Plus running

---

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

---

## License

MIT — see [LICENSE](LICENSE)
