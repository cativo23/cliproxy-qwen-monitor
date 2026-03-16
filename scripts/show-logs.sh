#!/usr/bin/env bash
#===============================================================================
# CLIProxyAPI Qwen Monitor — Log Viewer
#===============================================================================
# Pretty-prints monitor and restart logs with colors and stats.
#
# Usage:
#   ./show-logs.sh              # Show both logs (last 30 lines each)
#   ./show-logs.sh -f           # Follow monitor log in real-time
#   ./show-logs.sh -n 50        # Show last 50 lines
#   ./show-logs.sh --restarts   # Show only restart history
#   ./show-logs.sh --monitor    # Show only monitor log
#   ./show-logs.sh --stats      # Show restart statistics
#===============================================================================

set -euo pipefail

#-------------------------------------------------------------------------------
# Configuration
#-------------------------------------------------------------------------------
MONITOR_LOG="${MONITOR_LOG:-/tmp/cliproxyapi-monitor.log}"
RESTART_LOG="${RESTART_LOG:-/tmp/cliproxyapi-restarts.log}"
LINES=30
MODE="both"  # both | monitor | restarts | stats | follow

#-------------------------------------------------------------------------------
# Colors (TTY-safe)
#-------------------------------------------------------------------------------
if [[ -t 1 ]]; then
    RST=$(tput sgr0 2>/dev/null || true)
    BOLD=$(tput bold 2>/dev/null || true)
    DIM=$(tput dim 2>/dev/null || true)
    RED=$(tput setaf 1 2>/dev/null || true)
    GREEN=$(tput setaf 2 2>/dev/null || true)
    YELLOW=$(tput setaf 3 2>/dev/null || true)
    BLUE=$(tput setaf 4 2>/dev/null || true)
    MAGENTA=$(tput setaf 5 2>/dev/null || true)
    CYAN=$(tput setaf 6 2>/dev/null || true)
    WHITE=$(tput setaf 7 2>/dev/null || true)
    BG_RED=$(tput setab 1 2>/dev/null || true)
    BG_GREEN=$(tput setab 2 2>/dev/null || true)
    BG_BLUE=$(tput setab 4 2>/dev/null || true)
else
    RST="" BOLD="" DIM="" RED="" GREEN="" YELLOW="" BLUE="" MAGENTA="" CYAN="" WHITE="" BG_RED="" BG_GREEN="" BG_BLUE=""
fi

#-------------------------------------------------------------------------------
# Parse arguments
#-------------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        -f|--follow)     MODE="follow"; shift ;;
        -n|--lines)      LINES="$2"; shift 2 ;;
        --restarts)      MODE="restarts"; shift ;;
        --monitor)       MODE="monitor"; shift ;;
        --stats)         MODE="stats"; shift ;;
        -h|--help)
            echo "Usage: show-logs.sh [-f] [-n LINES] [--restarts|--monitor|--stats]"
            echo ""
            echo "Options:"
            echo "  -f, --follow      Follow monitor log in real-time"
            echo "  -n, --lines N     Number of lines to show (default: 30)"
            echo "  --restarts        Show only restart history"
            echo "  --monitor         Show only monitor log"
            echo "  --stats           Show restart statistics"
            echo "  -h, --help        Show this help"
            exit 0
            ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

#-------------------------------------------------------------------------------
# Helpers
#-------------------------------------------------------------------------------
separator() {
    local char="${1:-─}"
    local width
    width=$(tput cols 2>/dev/null || echo 80)
    printf '%*s\n' "$width" '' | tr ' ' "$char"
}

header() {
    local title="$1"
    local icon="${2:-}"
    echo ""
    echo "${BOLD}${CYAN}${icon} ${title}${RST}"
    separator "─"
}

colorize_monitor_line() {
    local line="$1"

    # Colorize by log level
    if [[ "$line" =~ \[ERROR\] ]]; then
        echo "${RED}${line}${RST}"
    elif [[ "$line" =~ \[WARN\] ]]; then
        echo "${YELLOW}${line}${RST}"
    elif [[ "$line" =~ \[SUCCESS\] ]]; then
        echo "${GREEN}${line}${RST}"
    elif [[ "$line" =~ \[DEBUG\] ]]; then
        echo "${DIM}${line}${RST}"
    elif [[ "$line" =~ DETECTED ]]; then
        echo "${BOLD}${YELLOW}⚡${RST} ${YELLOW}${line}${RST}"
    elif [[ "$line" =~ Restarting ]]; then
        echo "${MAGENTA}🔄${RST} ${line}"
    elif [[ "$line" =~ "Container restarted" ]]; then
        echo "${GREEN}✅${RST} ${line}"
    elif [[ "$line" =~ "Starting monitor" ]]; then
        echo "${CYAN}▶${RST}  ${line}"
    elif [[ "$line" =~ "No errors" ]]; then
        echo "${DIM}${line}${RST}"
    else
        echo "   ${line}"
    fi
}

colorize_restart_line() {
    local line="$1"

    # Format: 2026-03-16 01:19:55 - Restart (quota=1, cooling=1)
    local ts qwen cooling
    ts=$(echo "$line" | grep -oE '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}' 2>/dev/null) || ts=""
    qwen=$(echo "$line" | grep -oE '(qwen|quota)=[0-9]+' | grep -oE '[0-9]+' 2>/dev/null) || qwen="?"
    cooling=$(echo "$line" | grep -oE 'cooling=[0-9]+' | grep -oE '[0-9]+' 2>/dev/null) || cooling="?"

    if [[ -n "$ts" ]]; then
        printf "  ${DIM}%s${RST}  ${RED}🔄 restart${RST}  quota=${YELLOW}%s${RST}  cooling=${CYAN}%s${RST}\n" "$ts" "$qwen" "$cooling"
    else
        echo "  $line"
    fi
}

#-------------------------------------------------------------------------------
# Check monitor status
#-------------------------------------------------------------------------------
show_status() {
    local pid_file="/tmp/qwen-monitor.pid"
    local pid=""
    local status_icon status_text

    if [[ -f "$pid_file" ]]; then
        pid=$(cat "$pid_file" 2>/dev/null)
        if kill -0 "$pid" 2>/dev/null; then
            status_icon="${BG_GREEN}${WHITE}${BOLD} RUNNING ${RST}"
            status_text="PID ${pid}"
        else
            status_icon="${BG_RED}${WHITE}${BOLD} STOPPED ${RST}"
            status_text="stale PID file"
        fi
    else
        status_icon="${BG_RED}${WHITE}${BOLD} STOPPED ${RST}"
        status_text="no PID file"
    fi

    echo ""
    echo "  ${BOLD}Qwen Monitor${RST}  ${status_icon}  ${DIM}${status_text}${RST}"
    echo ""
}

#-------------------------------------------------------------------------------
# Stats
#-------------------------------------------------------------------------------
show_stats() {
    header "Restart Statistics" "📊"

    if [[ ! -f "$RESTART_LOG" ]] || [[ ! -s "$RESTART_LOG" ]]; then
        echo "  ${DIM}No restarts recorded yet.${RST}"
        return
    fi

    local total today last_hour last_restart

    total=$(wc -l < "$RESTART_LOG")

    today=$(grep -c "^$(date '+%Y-%m-%d')" "$RESTART_LOG" 2>/dev/null) || today=0

    local one_hour_ago
    one_hour_ago=$(date -d '1 hour ago' '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date -v-1H '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "")
    if [[ -n "$one_hour_ago" ]]; then
        last_hour=0
        while IFS= read -r line; do
            local line_ts
            line_ts=$(echo "$line" | grep -oE '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}' 2>/dev/null) || continue
            [[ -z "$line_ts" ]] && continue
            if [[ "$line_ts" > "$one_hour_ago" ]]; then
                ((last_hour++)) || true
            fi
        done < "$RESTART_LOG"
    else
        last_hour="?"
    fi

    last_restart=$(tail -1 "$RESTART_LOG" | grep -oE '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}' 2>/dev/null) || last_restart="never"

    echo ""
    printf "  ${BOLD}%-20s${RST} %s\n" "Total restarts:" "${YELLOW}${total}${RST}"
    printf "  ${BOLD}%-20s${RST} %s\n" "Today:" "${CYAN}${today}${RST}"
    printf "  ${BOLD}%-20s${RST} %s\n" "Last hour:" "${MAGENTA}${last_hour}${RST}"
    printf "  ${BOLD}%-20s${RST} %s\n" "Last restart:" "${DIM}${last_restart}${RST}"
    echo ""

    # Restarts per day breakdown
    echo "  ${BOLD}Daily breakdown:${RST}"
    awk '{print $1}' "$RESTART_LOG" | sort | uniq -c | sort -k2 | while read -r count day; do
        local bar=""
        local bar_len=$((count > 50 ? 50 : count))
        for ((b=0; b<bar_len; b++)); do bar+="█"; done || true

        if [[ "$count" -gt 20 ]]; then
            printf "    ${DIM}%s${RST}  ${RED}%4d${RST} ${RED}%s${RST}\n" "$day" "$count" "$bar"
        elif [[ "$count" -gt 5 ]]; then
            printf "    ${DIM}%s${RST}  ${YELLOW}%4d${RST} ${YELLOW}%s${RST}\n" "$day" "$count" "$bar"
        else
            printf "    ${DIM}%s${RST}  ${GREEN}%4d${RST} ${GREEN}%s${RST}\n" "$day" "$count" "$bar"
        fi
    done
    echo ""
}

#-------------------------------------------------------------------------------
# Show monitor log
#-------------------------------------------------------------------------------
show_monitor_log() {
    header "Monitor Log" "📋"

    if [[ ! -f "$MONITOR_LOG" ]]; then
        echo "  ${DIM}No monitor log found at ${MONITOR_LOG}${RST}"
        return
    fi

    echo "  ${DIM}${MONITOR_LOG} (last ${LINES} lines)${RST}"
    echo ""

    tail -"$LINES" "$MONITOR_LOG" | while IFS= read -r line; do
        colorize_monitor_line "$line"
    done
    echo ""
}

#-------------------------------------------------------------------------------
# Show restart log
#-------------------------------------------------------------------------------
show_restart_log() {
    header "Restart History" "🔄"

    if [[ ! -f "$RESTART_LOG" ]] || [[ ! -s "$RESTART_LOG" ]]; then
        echo "  ${DIM}No restarts recorded yet.${RST}"
        return
    fi

    echo "  ${DIM}${RESTART_LOG} (last ${LINES} entries)${RST}"
    echo ""

    tail -"$LINES" "$RESTART_LOG" | while IFS= read -r line; do
        colorize_restart_line "$line"
    done
    echo ""
}

#-------------------------------------------------------------------------------
# Follow mode
#-------------------------------------------------------------------------------
follow_log() {
    header "Following Monitor Log (Ctrl+C to stop)" "👀"

    if [[ ! -f "$MONITOR_LOG" ]]; then
        echo "  ${DIM}Waiting for log file: ${MONITOR_LOG}${RST}"
    fi

    tail -"$LINES" "$MONITOR_LOG" 2>/dev/null | while IFS= read -r line; do
        colorize_monitor_line "$line"
    done

    separator "─"
    echo "${DIM}  ▼ live tail ▼${RST}"
    echo ""

    tail -f "$MONITOR_LOG" 2>/dev/null | while IFS= read -r line; do
        colorize_monitor_line "$line"
    done
}

#-------------------------------------------------------------------------------
# Main
#-------------------------------------------------------------------------------
case "$MODE" in
    both)
        show_status
        show_stats
        show_monitor_log
        show_restart_log
        ;;
    monitor)
        show_status
        show_monitor_log
        ;;
    restarts)
        show_restart_log
        show_stats
        ;;
    stats)
        show_status
        show_stats
        ;;
    follow)
        show_status
        follow_log
        ;;
esac
