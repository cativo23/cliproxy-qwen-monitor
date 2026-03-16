<div align="center">

<pre>
   ________    ________                        ___    ____  ____
  / ____/ /   /  _/ __ \_________  _  ____  __/   |  / __ \/  _/
 / /   / /    / // /_/ / ___/ __ \| |/_/ / / / /| | / /_/ // /
/ /___/ /____/ // ____/ /  / /_/ />  </ /_/ / ___ |/ ____// /
\____/_____/___/_/   /_/   \____/_/|_|\__, /_/  |_/_/   /___/
                                     /____/
   ____                         __  ___            _ __
  / __ \_      _____  ____     /  |/  /___  ____  (_) /_____  _____
 / / / / | /| / / _ \/ __ \   / /|_/ / __ \/ __ \/ / __/ __ \/ ___/
/ /_/ /| |/ |/ /  __/ / / /  / /  / / /_/ / / / / / /_/ /_/ / /
\___\_\|__/|__/\___/_/ /_/  /_/  /_/\____/_/ /_/_/\__/\____/_/
</pre>

**Auto-restart for CLIProxyAPI when Qwen quota errors occur.**

Monitor and automatically restart CLIProxyAPI Plus when Qwen OAuth accounts hit daily quota limits.

[![GitHub release](https://img.shields.io/github/v/release/cativo23/cliproxy-qwen-monitor?include_prereleases&style=flat-square)](https://github.com/cativo23/cliproxy-qwen-monitor/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](CONTRIBUTING.md)
[![Bash](https://img.shields.io/badge/Bash-5%2B-4EAA25?style=flat-square&logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)

</div>

---

## Table of Contents

- [Problem](#problem)
- [Solution](#solution)
- [Quick Start](#quick-start)
- [Scripts](#scripts)
- [How It Works](#how-it-works)
- [Configuration](#configuration)
- [Logs](#logs)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Contributing](#contributing)
- [License](#license)

---

## Problem

**CLIProxyAPI Plus** has a bug where Qwen OAuth quota handling blocks ALL accounts instead of rotating:

- Qwen has 2 types of 429 errors: **daily quota** (real) and **rate limit** (temporary, ~60 RPM)
- `wrapQwenError()` in CLIProxyAPI treats both as "quota exceeded" → cooldown until midnight (Beijing time)
- When ONE account hits 429, ALL accounts get marked as "cooling down"
- Result: No requests work until manual restart

**Workaround was manual:**
```bash
./setup-local.sh --down && ./setup-local.sh
```

---

## Solution

This project provides automatic restart when Qwen errors are detected:

- **Monitors** CLIProxyAPI logs every 2 seconds
- **Detects** Qwen-specific error patterns
- **Restarts** container immediately via `docker compose restart`
- **Logs** all events for debugging

---

## Quick Start

**1. Clone the repository:**

```bash
git clone https://github.com/cativo23/cliproxy-qwen-monitor.git
cd cliproxy-qwen-monitor
```

**2. Start the monitor in background:**

```bash
# From your CLIProxyAPI directory (where docker-compose.local.yml exists)
nohup bash /path/to/cliproxy-qwen-monitor/scripts/auto-restart-qwen.sh &
```

**3. Verify it's running:**

```bash
ps aux | grep auto-restart-qwen
tail -f /tmp/cliproxyapi-monitor.log
```

---

## Scripts

| Script | Description | Usage |
|:-------|:------------|:------|
| **`auto-restart-qwen.sh`** | Main monitor - auto-restarts CLIProxyAPI on Qwen errors | `./scripts/auto-restart-qwen.sh` |
| **`test-qwen-quota.sh`** | Test quota through CLIProxyAPI proxy | `./scripts/test-qwen-quota.sh [count]` |
| **`test-qwen-direct.sh`** | Test quota directly against Qwen API | `./scripts/test-qwen-direct.sh [count]` |

### auto-restart-qwen.sh

**What it does:**
- Checks if `cliproxyapi` container exists
- Reads last 100 lines from `/CLIProxyAPI/logs/main.log`
- Detects error patterns (case-insensitive):
  - `qwen quota exceeded`
  - `cooling down`
  - `Suspended client.*quota`
- Restarts container with `docker compose -f docker-compose.local.yml restart`
- Enforces 10-second cooldown between restarts

**Configuration (edit script):**

```bash
CHECK_INTERVAL=2      # Seconds between log checks
COOLDOWN=10           # Seconds between restarts
CONTAINER="cliproxyapi"
COMPOSE_FILE="docker-compose.local.yml"
```

### test-qwen-quota.sh

**Purpose:** Test quota rotation through CLIProxyAPI.

```bash
# Send 100 requests (default)
./scripts/test-qwen-quota.sh

# Send 500 requests
./scripts/test-qwen-quota.sh 500
```

**Config:**
```bash
API_KEY="sk-..."        # Your CLIProxyAPI key
PROXY_URL="http://127.0.0.1:8317"
MODEL="coder-model"
```

### test-qwen-direct.sh

**Purpose:** Test quota directly against Qwen API (bypass CLIProxyAPI).

```bash
# Send 1000 requests (default)
./scripts/test-qwen-direct.sh

# Send 500 requests
./scripts/test-qwen-direct.sh 500
```

**Config:**
```bash
TOKEN="AfS..."          # Qwen OAuth token
MODEL="coder-model"
```

---

## How It Works

```
┌─────────────────────────────────────────────────────────────┐
│                    Monitor Loop (2s interval)                │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  docker exec cliproxyapi tail -100 /CLIProxyAPI/logs/main.log │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              Detect Error Patterns (grep -ciE)               │
│  • qwen quota exceeded                                      │
│  • cooling down                                             │
│  • Suspended client.*quota                                  │
└─────────────────────────────────────────────────────────────┘
                              │
                    ┌─────────┴─────────┐
                    │   errors > 0?     │
                    └─────────┬─────────┘
                              │
              ┌───────────────┼───────────────┐
              │ NO            │ YES           │
              │               ▼               │
              │    ┌──────────────────────┐   │
              │    │ Check 10s cooldown   │   │
              │    └──────────┬───────────┘   │
              │               │               │
              │         ┌─────┴─────┐         │
              │         │ expired?  │         │
              │         └─────┬─────┘         │
              │               │               │
              │    ┌──────────┼──────────┐   │
              │    │ YES      │ NO       │   │
              │    │          │          │   │
              │    │          ▼          │   │
              │    │ ┌─────────────────┐ │   │
              │    │ │ docker compose  │ │   │
              │    │ │ restart         │ │   │
              │    │ └─────────────────┘ │   │
              │    │          │          │   │
              │    │          ▼          │   │
              │    │ Log success/failure │   │
              │    └──────────┬──────────┘   │
              │               │               │
              └───────────────┴───────────────┘
                              │
                              ▼
                    Sleep 2s, repeat
```

---

## Logs

**Monitor Log:** `/tmp/cliproxyapi-monitor.log`

```
=== CLIProxyAPI Qwen Auto-Restart ===
Reinicia INMEDIATAMENTE al detectar errores de Qwen
Check interval: 2s
Log: /tmp/cliproxyapi-monitor.log
Press Ctrl+C para detener

[2026-03-15 15:52:03] DETECTADO: quota=3, cooling=1, suspended=0
[2026-03-15 15:52:03] Reiniciando cliproxyapi con docker compose...
[2026-03-15 15:52:05] SUCCESS: Reiniciado
```

**Restart Log:** `/tmp/cliproxyapi-restarts.log`

```
2026-03-15 15:52:05 - Restart (qwen=3, cooling=1)
2026-03-15 15:53:12 - Restart (qwen=2, cooling=0)
2026-03-15 16:04:45 - Restart (qwen=5, cooling=2)
```

**View logs:**
```bash
# Real-time monitor log
tail -f /tmp/cliproxyapi-monitor.log

# Restart history
cat /tmp/cliproxyapi-restarts.log

# Count total restarts
wc -l < /tmp/cliproxyapi-restarts.log
```

---

## Prerequisites

| Dependency | Required | Install |
|:-----------|:--------:|:--------|
| Docker | Yes | [docker.com](https://docs.docker.com/get-docker/) |
| Docker Compose plugin | Yes | Included in Docker Desktop |
| Bash 5.0+ | Yes | `brew install bash` (macOS) |
| CLIProxyAPI Plus | Yes | [router-for-me/CLIProxyAPIPlus](https://github.com/router-for-me/CLIProxyAPIPlus) |

---

## Project Structure

```
cliproxy-qwen-monitor/
  scripts/
    auto-restart-qwen.sh    # Main monitor script
    test-qwen-quota.sh      # Test through proxy
    test-qwen-direct.sh     # Test direct API
  docs/
    (future documentation)
  .github/
    ISSUE_TEMPLATE/
      bug_report.md
      feature_request.md
  README.md
  CONTRIBUTING.md
  CHANGELOG.md
  LICENSE
```

---

## Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on branching, commit format, and the PR process.

### Quick Start for Contributors

```bash
# Fork and clone
git clone https://github.com/<your-user>/cliproxy-qwen-monitor.git
cd cliproxy-qwen-monitor

# Create branch from develop
git checkout develop
git checkout -b feature/my-feature

# Make changes, commit with gitmoji
git commit -m "✨ feat: add new feature"

# Push and open PR to develop
git push origin feature/my-feature
```

---

## Troubleshooting

### Container not restarting

**Check if container name matches:**
```bash
docker ps --format '{{.Names}}' | grep cliproxy
```

**Update `CONTAINER` variable in script if needed.**

### Permission denied on docker commands

**Add user to docker group:**
```bash
sudo usermod -aG docker $USER
newgrp docker
```

### Monitor not detecting errors

**Verify log path inside container:**
```bash
docker exec cliproxyapi ls -la /CLIProxyAPI/logs/
```

**Check error patterns match your logs:**
```bash
docker exec cliproxyapi tail -100 /CLIProxyAPI/logs/main.log | grep -i qwen
```

---

## License

MIT — see [LICENSE](LICENSE) for details.
