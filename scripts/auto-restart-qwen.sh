#!/bin/bash
# Auto-restart CLIProxyAPI cuando detecta errores de Qwen
# Reinicia INMEDIATAMENTE al detectar error
# Uso: ./auto-restart-qwen.sh (dejar corriendo en background)

MONITOR_LOG="/tmp/cliproxyapi-monitor.log"
RESTART_LOG="/tmp/cliproxyapi-restarts.log"
CONTAINER="cliproxyapi"
COMPOSE_FILE="docker-compose.local.yml"
CHECK_INTERVAL=2  # Segundos entre chequeos

log_msg() {
  echo "$1" | tee -a "$MONITOR_LOG"
}

log_msg "=== CLIProxyAPI Qwen Auto-Restart ==="
log_msg "Reinicia INMEDIATAMENTE al detectar errores de Qwen"
log_msg "Check interval: ${CHECK_INTERVAL}s"
log_msg "Log: $MONITOR_LOG"
log_msg "Press Ctrl+C para detener"
log_msg ""

last_restart=0

while true; do
  # Verificar si el container existe
  if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
    log_msg "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Container $CONTAINER no encontrado"
    sleep 10
    continue
  fi

  # Buscar errores de Qwen en el archivo main.log (donde realmente se escriben)
  logs=$(docker exec "$CONTAINER" tail -100 /CLIProxyAPI/logs/main.log 2>&1)

  # Detectar errores específicos de Qwen
  quota_error=$(echo "$logs" | grep -ciE "qwen quota exceeded" 2>/dev/null) || quota_error=0
  cooling_down=$(echo "$logs" | grep -ci "cooling down" 2>/dev/null) || cooling_down=0
  suspended=$(echo "$logs" | grep -ci "Suspended client.*quota" 2>/dev/null) || suspended=0

  total_errors=$((quota_error + cooling_down + suspended))

  if [ "$total_errors" -gt 0 ]; then
    now=$(date +%s)

    # Solo reiniciar si pasaron al menos 10s desde el último restart
    if [ $((now - last_restart)) -gt 10 ]; then
      log_msg "[$(date '+%Y-%m-%d %H:%M:%S')] DETECTADO: quota=$quota_error, cooling=$cooling_down, suspended=$suspended"
      log_msg "[$(date '+%Y-%m-%d %H:%M:%S')] Reiniciando $CONTAINER con docker compose..."

      # Usar docker compose restart (más confiable que docker restart)
      cd "$(dirname "${BASH_SOURCE[0]}")/.."
      docker compose -f "$COMPOSE_FILE" restart "$CONTAINER" 2>&1 | tee -a "$MONITOR_LOG"

      if [ ${PIPESTATUS[0]} -eq 0 ]; then
        log_msg "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: Reiniciado"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Restart (qwen=$quota_error, cooling=$cooling_down)" >> "$RESTART_LOG"
        last_restart=$now
      else
        log_msg "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Falló el restart"
      fi
    fi
  fi

  sleep $CHECK_INTERVAL
done
