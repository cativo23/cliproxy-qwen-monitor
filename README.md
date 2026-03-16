<div align="center">

**CLIProxyAPI Qwen Monitor**

Reinicia automáticamente CLIProxyAPI cuando detecta errores de quota de Qwen.

[![GitHub release](https://img.shields.io/github/v/release/cativo23/cliproxy-qwen-monitor?include_prereleases&style=flat-square)](https://github.com/cativo23/cliproxy-qwen-monitor/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](LICENSE)

</div>

---

## Problema

CLIProxyAPI Plus tiene un bug: cuando una cuenta de Qwen alcanza su quota diaria, **todas** las cuentas del pool se bloquean hasta que se reinicia el contenedor manualmente.

## Solución

Este script monitorea los logs de CLIProxyAPI y reinicia el contenedor automáticamente cuando detecta errores de quota de Qwen.

- **Monitorea** cada 2 segundos
- **Detecta** solo errores de Qwen (no de otros providers)
- **Reinicia** el contenedor con cooldown de 10 segundos
- **Registra** todos los eventos para debugging

---

## Inicio Rápido

```bash
# 1. Clonar el repositorio
git clone https://github.com/cativo23/cliproxy-qwen-monitor.git
cd cliproxy-qwen-monitor

# 2. Iniciar el monitor (background)
nohup ./scripts/auto-restart-qwen.sh &

# 3. Verificar que está corriendo
ps aux | grep auto-restart-qwen
tail -f /tmp/cliproxyapi-monitor.log
```

### Detener

```bash
kill $(cat /tmp/qwen-monitor.pid) 2>/dev/null || pkill -f auto-restart-qwen
```

---

## Uso

```bash
# Valores por defecto
./scripts/auto-restart-qwen.sh

# Con opciones personalizadas
./scripts/auto-restart-qwen.sh --interval 5 --cooldown 30 --verbose

# Ver ayuda
./scripts/auto-restart-qwen.sh --help
```

### Opciones

| Opción | Descripción | Default |
|--------|-------------|---------|
| `-i, --interval SECS` | Intervalo de chequeo | 2 |
| `-c, --cooldown SECS` | Cooldown entre restarts | 10 |
| `-n, --container NAME` | Nombre del contenedor | cliproxyapi |
| `-v, --verbose` | Modo debug | - |
| `-q, --quiet` | Solo errores | - |
| `-h, --help` | Mostrar ayuda | - |

### Archivo de Configuración

Opcional: `/etc/qwen-monitor/config` o `~/.config/qwen-monitor/config`

```bash
CHECK_INTERVAL=2
COOLDOWN_PERIOD=10
CONTAINER_NAME=cliproxyapi
VERBOSE=false
```

---

## Scripts

| Script | Descripción |
|--------|-------------|
| `auto-restart-qwen.sh` | Monitor principal |
| `show-logs.sh` | Ver logs con colores y stats |
| `test-qwen-quota.sh` | Test de quota vía proxy |
| `test-qwen-direct.sh` | Test de quota directo a API |

---

## Logs

| Log | Ubicación |
|-----|-----------|
| Monitor | `/tmp/cliproxyapi-monitor.log` |
| Restarts | `/tmp/cliproxyapi-restarts.log` |
| PID | `/tmp/qwen-monitor.pid` |

### Ver logs

```bash
# En tiempo real
tail -f /tmp/cliproxyapi-monitor.log

# Con formato y stats
./scripts/show-logs.sh

# Historial de restarts
cat /tmp/cliproxyapi-restarts.log
```

---

## Instalación como Servicio (Linux)

```bash
# Copiar servicio systemd
sudo cp systemd/qwen-monitor.service /etc/systemd/system/

# Ajustar paths en el service (opcional)
sudo nano /etc/systemd/system/qwen-monitor.service

# Habilitar e iniciar
sudo systemctl daemon-reload
sudo systemctl enable --now qwen-monitor

# Ver estado
sudo systemctl status qwen-monitor
journalctl -u qwen-monitor -f
```

---

## Requisitos

- Docker + Docker Compose plugin
- Bash 5.0+
- CLIProxyAPI Plus corriendo

---

## Estructura del Proyecto

```
cliproxy-qwen-monitor/
├── scripts/
│   ├── auto-restart-qwen.sh    # Monitor principal
│   ├── show-logs.sh            # Visor de logs
│   ├── test-qwen-quota.sh      # Test proxy
│   └── test-qwen-direct.sh     # Test directo
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

MIT — ver [LICENSE](LICENSE)
