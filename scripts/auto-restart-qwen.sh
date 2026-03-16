#!/usr/bin/env bash
#===============================================================================
# CLIProxyAPI Qwen Auto-Restart Monitor
#===============================================================================
# Reinicia automáticamente CLIProxyAPI cuando detecta errores de quota de Qwen
#
# Uso: auto-restart-qwen.sh [OPCIONES]
#
# Ejemplos:
#   ./auto-restart-qwen.sh                    # Usar valores por defecto
#   ./auto-restart-qwen.sh -i 5 -c 30         # Intervalo 5s, cooldown 30s
#   ./auto-restart-qwen.sh --config /etc/qwen-monitor.conf
#   ./auto-restart-qwen.sh --verbose          # Modo detallado
#
# Para más información: https://github.com/cativo23/cliproxy-qwen-monitor
#===============================================================================

set -euo pipefail

#-------------------------------------------------------------------------------
# Constants
#-------------------------------------------------------------------------------
readonly SCRIPT_NAME="qwen-monitor"
readonly SCRIPT_VERSION="0.3.0"
readonly SCRIPT_AUTHOR="cativo23"
readonly SCRIPT_REPO="https://github.com/cativo23/cliproxy-qwen-monitor"

# Default configuration
readonly DEFAULT_CHECK_INTERVAL=2
readonly DEFAULT_COOLDOWN=10
readonly DEFAULT_CONTAINER="cliproxyapi"
readonly DEFAULT_COMPOSE_FILE="docker-compose.local.yml"
readonly DEFAULT_MONITOR_LOG="/tmp/cliproxyapi-monitor.log"
readonly DEFAULT_RESTART_LOG="/tmp/cliproxyapi-restarts.log"
readonly DEFAULT_ERROR_PATTERNS="qwen quota exceeded,cooling down,Suspended client.*quota"

# Error patterns (grep -E)
readonly QWEN_QUOTA_PATTERN="qwen quota exceeded"
readonly COOLING_DOWN_PATTERN="cooling down"
readonly SUSPENDED_PATTERN="Suspended client qwen-.*quota"

# Exit codes
readonly EXIT_SUCCESS=0
readonly EXIT_ERROR=1
readonly EXIT_INTERRUPTED=130

# Colors (TTY-safe)
declare -A COLORS=(
    [reset]=""
    [bold]=""
    [red]=""
    [green]=""
    [yellow]=""
    [blue]=""
    [cyan]=""
)

#-------------------------------------------------------------------------------
# Global Variables (mutable — set by parse_arguments / load_config_file)
#-------------------------------------------------------------------------------
check_interval="$DEFAULT_CHECK_INTERVAL"
cooldown_period="$DEFAULT_COOLDOWN"
container_name="$DEFAULT_CONTAINER"
compose_file="$DEFAULT_COMPOSE_FILE"
monitor_log="$DEFAULT_MONITOR_LOG"
restart_log="$DEFAULT_RESTART_LOG"
verbose=false
quiet=false
config_file=""
last_restart=0
last_restart_timestamp=""  # ISO timestamp of last restart, used to filter stale errors
running=true

#-------------------------------------------------------------------------------
# Functions: Color & Output
#-------------------------------------------------------------------------------
init_colors() {
    if [[ -t 1 ]]; then
        COLORS[reset]=$(tput sgr0 2>/dev/null || echo "")
        COLORS[bold]=$(tput bold 2>/dev/null || echo "")
        COLORS[red]=$(tput setaf 1 2>/dev/null || echo "")
        COLORS[green]=$(tput setaf 2 2>/dev/null || echo "")
        COLORS[yellow]=$(tput setaf 3 2>/dev/null || echo "")
        COLORS[blue]=$(tput setaf 4 2>/dev/null || echo "")
        COLORS[cyan]=$(tput setaf 6 2>/dev/null || echo "")
    fi
}

log_info() {
    if [[ "$quiet" == true ]]; then return 0; fi
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo -e "${COLORS[blue]}[INFO]${COLORS[reset]} $msg" | tee -a "$monitor_log"
}

log_success() {
    if [[ "$quiet" == true ]]; then return 0; fi
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo -e "${COLORS[green]}[SUCCESS]${COLORS[reset]} $msg" | tee -a "$monitor_log"
}

log_warning() {
    if [[ "$quiet" == true ]]; then return 0; fi
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1"
    echo -e "${COLORS[yellow]}[WARN]${COLORS[reset]} $msg" | tee -a "$monitor_log" >&2
}

log_error() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1"
    echo -e "${COLORS[red]}[ERROR]${COLORS[reset]} $msg" | tee -a "$monitor_log" >&2
}

log_verbose() {
    if [[ "$verbose" != true ]]; then return 0; fi
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] [DEBUG] $1"
    echo -e "${COLORS[cyan]}[DEBUG]${COLORS[reset]} $msg" | tee -a "$monitor_log"
}

#-------------------------------------------------------------------------------
# Functions: Help & Version
#-------------------------------------------------------------------------------
show_version() {
    echo "${SCRIPT_NAME} version ${SCRIPT_VERSION}"
}

show_help() {
    cat << EOF
${COLORS[bold]}${SCRIPT_NAME}${COLORS[reset]} - Auto-restart CLIProxyAPI on Qwen quota errors

${COLORS[bold]}USAGE:${COLORS[reset]}
    ${SCRIPT_NAME} [OPTIONS]

${COLORS[bold]}OPTIONS:${COLORS[reset]}
    -i, --interval SECONDS      Check interval in seconds (default: ${DEFAULT_CHECK_INTERVAL})
    -c, --cooldown SECONDS      Cooldown between restarts (default: ${DEFAULT_COOLDOWN})
    -n, --container NAME        Container name (default: ${DEFAULT_CONTAINER})
    -f, --compose-file FILE     Docker Compose file (default: ${DEFAULT_COMPOSE_FILE})
    -m, --monitor-log FILE      Monitor log file (default: ${DEFAULT_MONITOR_LOG})
    -r, --restart-log FILE      Restart history log (default: ${DEFAULT_RESTART_LOG})
    -C, --config FILE           Load configuration from file
    -v, --verbose               Enable verbose/debug output
    -q, --quiet                 Suppress non-error output
    -h, --help                  Show this help message
    -V, --version               Show version information

${COLORS[bold]}EXAMPLES:${COLORS[reset]}
    ${SCRIPT_NAME}                              # Run with defaults
    ${SCRIPT_NAME} -i 5 -c 30                   # 5s interval, 30s cooldown
    ${SCRIPT_NAME} --verbose                    # Debug mode
    ${SCRIPT_NAME} --config /etc/qwen-monitor.conf

${COLORS[bold]}CONFIGURATION FILE FORMAT:${COLORS[reset]}
    # /etc/qwen-monitor.conf or ~/.config/qwen-monitor/config
    CHECK_INTERVAL=2
    COOLDOWN_PERIOD=10
    CONTAINER_NAME=cliproxyapi
    COMPOSE_FILE=docker-compose.local.yml
    MONITOR_LOG=/tmp/cliproxyapi-monitor.log
    RESTART_LOG=/tmp/cliproxyapi-restarts.log
    VERBOSE=false

${COLORS[bold]}ERROR PATTERNS DETECTED:${COLORS[reset]}
    - "${QWEN_QUOTA_PATTERN}"
    - "${COOLING_DOWN_PATTERN}"
    - "${SUSPENDED_PATTERN}"

${COLORS[bold]}LOGS:${COLORS[reset]}
    Monitor:  ${DEFAULT_MONITOR_LOG}
    Restarts: ${DEFAULT_RESTART_LOG}

${COLORS[bold]}MORE INFO:${COLORS[reset]}
    Documentation: ${SCRIPT_REPO}
    Issues:        ${SCRIPT_REPO}/issues

EOF
}

#-------------------------------------------------------------------------------
# Functions: Configuration
#-------------------------------------------------------------------------------
load_config_file() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        log_error "Configuration file not found: $file"
        return $EXIT_ERROR
    fi

    log_verbose "Loading configuration from: $file"

    # shellcheck source=/dev/null
    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue

        # Trim whitespace
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs)

        case "$key" in
            CHECK_INTERVAL) check_interval="$value" ;;
            COOLDOWN_PERIOD) cooldown_period="$value" ;;
            CONTAINER_NAME) container_name="$value" ;;
            COMPOSE_FILE) compose_file="$value" ;;
            MONITOR_LOG) monitor_log="$value" ;;
            RESTART_LOG) restart_log="$value" ;;
            VERBOSE) [[ "$value" == "true" ]] && verbose=true ;;
            QUIET) [[ "$value" == "true" ]] && quiet=true ;;
        esac
    done < "$file"

    log_verbose "Configuration loaded successfully"
}

validate_config() {
    local errors=()

    # Validate numeric values
    if ! [[ "$check_interval" =~ ^[0-9]+$ ]] || [[ "$check_interval" -lt 1 ]]; then
        errors+=("CHECK_INTERVAL must be a positive integer (got: $check_interval)")
    fi

    if ! [[ "$cooldown_period" =~ ^[0-9]+$ ]] || [[ "$cooldown_period" -lt 1 ]]; then
        errors+=("COOLDOWN_PERIOD must be a positive integer (got: $cooldown_period)")
    fi

    # Validate container name
    if [[ -z "$container_name" ]]; then
        errors+=("CONTAINER_NAME cannot be empty")
    fi

    # Validate compose file exists if path is absolute
    if [[ "$compose_file" == /* ]] && [[ ! -f "$compose_file" ]]; then
        errors+=("COMPOSE_FILE not found: $compose_file")
    fi

    # Report errors
    if [[ ${#errors[@]} -gt 0 ]]; then
        log_error "Configuration validation failed:"
        for err in "${errors[@]}"; do
            echo "  - $err" >&2
        done
        return $EXIT_ERROR
    fi

    log_verbose "Configuration validated"
    return $EXIT_SUCCESS
}

#-------------------------------------------------------------------------------
# Functions: Dependencies
#-------------------------------------------------------------------------------
check_dependencies() {
    local missing=()
    local deps=("docker" "docker-compose")

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            missing+=("$dep")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing dependencies: ${missing[*]}"
        log_info "Install missing dependencies and try again"
        return $EXIT_ERROR
    fi

    # Check Docker is running
    if ! docker info &>/dev/null 2>&1; then
        log_error "Docker daemon is not running"
        log_info "Start Docker Desktop or 'systemctl start docker'"
        return $EXIT_ERROR
    fi

    log_verbose "All dependencies satisfied"
    return $EXIT_SUCCESS
}

#-------------------------------------------------------------------------------
# Functions: Signal Handling
#-------------------------------------------------------------------------------
cleanup() {
    running=false
    log_info "Received shutdown signal, cleaning up..."

    # Remove PID file if exists
    local pid_file="/tmp/${SCRIPT_NAME}.pid"
    if [[ -f "$pid_file" ]]; then rm -f "$pid_file"; fi

    log_info "Monitor stopped. Goodbye!"
    exit $EXIT_SUCCESS
}

setup_signal_handlers() {
    trap cleanup SIGINT SIGTERM
    trap 'log_warning "Received SIGPIPE, ignoring"' SIGPIPE
}

#-------------------------------------------------------------------------------
# Functions: Core Logic
#-------------------------------------------------------------------------------
check_container_exists() {
    if ! docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
        log_error "Container '${container_name}' not found"
        log_info "Verify container name with: docker ps --format '{{.Names}}'"
        return 1
    fi
    return 0
}

get_container_logs() {
    local log_path="/CLIProxyAPI/logs/main.log"
    local lines="${1:-100}"

    docker exec "$container_name" tail -"$lines" "$log_path" 2>/dev/null || echo ""
}

detect_qwen_errors() {
    local logs="$1"
    local quota_count cooling_count suspended_count total
    local filtered_logs

    # NOTE: This function is called inside $(...), so all log output must go
    # to stderr (>&2) to avoid corrupting the return value on stdout.

    # Filter logs: only consider lines with timestamps AFTER the last restart
    # Log format: [2026-03-16 15:10:23] ...
    if [[ -n "$last_restart_timestamp" ]]; then
        filtered_logs=$(filter_logs_after_timestamp "$logs" "$last_restart_timestamp")
        log_verbose "Filtered logs: $(echo "$filtered_logs" | wc -l) lines after $last_restart_timestamp" >&2
    else
        filtered_logs="$logs"
    fi

    # If no lines remain after filtering, no new errors
    if [[ -z "$filtered_logs" ]]; then
        log_verbose "No log lines after last restart timestamp" >&2
        echo "0:0:0:0"
        return
    fi

    # Count error patterns (case-insensitive) only in NEW log lines
    quota_count=$(echo "$filtered_logs" | grep -ciE "$QWEN_QUOTA_PATTERN" 2>/dev/null) || quota_count=0
    cooling_count=$(echo "$filtered_logs" | grep -ciE "$COOLING_DOWN_PATTERN" 2>/dev/null) || cooling_count=0
    suspended_count=$(echo "$filtered_logs" | grep -ciE "$SUSPENDED_PATTERN" 2>/dev/null) || suspended_count=0

    total=$((quota_count + cooling_count + suspended_count))

    log_verbose "Error counts - quota=$quota_count, cooling=$cooling_count, suspended=$suspended_count (after ${last_restart_timestamp:-startup})" >&2

    echo "$total:$quota_count:$cooling_count:$suspended_count"
}

# Filter log lines that have a timestamp strictly after the given reference timestamp.
# Compares ISO timestamps lexicographically: "2026-03-16 15:10:23" > "2026-03-16 15:09:00"
filter_logs_after_timestamp() {
    local logs="$1"
    local ref_timestamp="$2"

    # Extract lines with timestamps and keep only those after ref_timestamp
    # Log format: [YYYY-MM-DD HH:MM:SS] ...
    while IFS= read -r line; do
        # Extract timestamp from line: [2026-03-16 15:10:23] → 2026-03-16 15:10:23
        local line_ts
        line_ts=$(echo "$line" | sed -n 's/^\[\([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\} [0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\)\].*/\1/p' 2>/dev/null)

        # Skip lines without timestamps
        if [[ -z "$line_ts" ]]; then
            continue
        fi

        # Lexicographic comparison works for ISO timestamps
        if [[ "$line_ts" > "$ref_timestamp" ]]; then
            echo "$line"
        fi
    done <<< "$logs"
}

restart_container() {
    local quota_val="${1:-0}"
    local cooling_val="${2:-0}"
    local now timestamp

    now=$(date +%s)
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Check cooldown
    if [[ $((now - last_restart)) -lt $cooldown_period ]]; then
        local remaining=$((cooldown_period - (now - last_restart)))
        log_verbose "Cooldown active, ${remaining}s remaining"
        return 1
    fi

    log_info "Restarting container '${container_name}' with docker-compose..."

    # Execute restart using docker-compose with the specified compose file
    local output exit_code
    if output=$(docker-compose -f "$compose_file" restart "$container_name" 2>&1); then
        exit_code=0
    else
        exit_code=$?
    fi

    if [[ $exit_code -eq 0 ]]; then
        log_success "Container restarted successfully"
        echo "$timestamp - Restart (quota=$quota_val, cooling=$cooling_val)" >> "$restart_log"
        last_restart=$now
        last_restart_timestamp="$timestamp"
        log_verbose "Updated last_restart_timestamp=$last_restart_timestamp"
        return 0
    else
        log_error "Failed to restart container (exit code: $exit_code)"
        log_verbose "Docker compose output: $output"
        return 1
    fi
}

monitor_loop() {
    log_info "Starting monitor loop (interval: ${check_interval}s)"

    while $running; do
        # Check container exists
        if ! check_container_exists; then
            sleep 10
            continue
        fi

        # Get recent logs
        local logs
        logs=$(get_container_logs 100)

        # Detect errors
        local error_data total_errors quota cooling suspended
        error_data=$(detect_qwen_errors "$logs")

        IFS=':' read -r total_errors quota cooling suspended <<< "$error_data"

        if [[ "$total_errors" -gt 0 ]]; then
            log_info "DETECTED: quota=$quota, cooling=$cooling, suspended=$suspended"
            restart_container "$quota" "$cooling" || true
        else
            log_verbose "No errors detected"
        fi

        # Sleep with interrupt check
        local i=0
        while [[ $i -lt $check_interval ]] && $running; do
            sleep 1
            ((i++)) || true
        done
    done
}

#-------------------------------------------------------------------------------
# Functions: Startup
#-------------------------------------------------------------------------------
print_banner() {
    if [[ "$quiet" == true ]]; then return 0; fi

    cat << EOF
${COLORS[bold]}${COLORS[cyan]}╔═══════════════════════════════════════════════════════════╗
║     CLIProxyAPI Qwen Auto-Restart Monitor                 ║
╠═══════════════════════════════════════════════════════════╣
║  Version: ${SCRIPT_VERSION}                                          ║
║  Interval: ${check_interval}s | Cooldown: ${cooldown_period}s                          ║
║  Container: ${container_name}                                     ║
║  Logs: ${monitor_log} ║
╠═══════════════════════════════════════════════════════════╣
║  Press Ctrl+C to stop                                     ║
╚═══════════════════════════════════════════════════════════╝${COLORS[reset]}

EOF
}

write_pid_file() {
    local pid_file="/tmp/${SCRIPT_NAME}.pid"
    echo $$ > "$pid_file"
    log_verbose "PID file written: $pid_file (PID: $$)"
}

#-------------------------------------------------------------------------------
# Main: Argument Parsing
#-------------------------------------------------------------------------------
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -i|--interval)
                check_interval="$2"
                shift 2
                ;;
            -c|--cooldown)
                cooldown_period="$2"
                shift 2
                ;;
            -n|--container)
                container_name="$2"
                shift 2
                ;;
            -f|--compose-file)
                compose_file="$2"
                shift 2
                ;;
            -m|--monitor-log)
                monitor_log="$2"
                shift 2
                ;;
            -r|--restart-log)
                restart_log="$2"
                shift 2
                ;;
            -C|--config)
                config_file="$2"
                shift 2
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            -q|--quiet)
                quiet=true
                shift
                ;;
            -h|--help)
                show_help
                exit $EXIT_SUCCESS
                ;;
            -V|--version)
                show_version
                exit $EXIT_SUCCESS
                ;;
            -*)
                log_error "Unknown option: $1"
                echo "Use '${SCRIPT_NAME} --help' for usage information" >&2
                exit $EXIT_ERROR
                ;;
            *)
                log_error "Unexpected argument: $1"
                exit $EXIT_ERROR
                ;;
        esac
    done
}

#-------------------------------------------------------------------------------
# Main: Entry Point
#-------------------------------------------------------------------------------
main() {
    # Initialize
    init_colors
    parse_arguments "$@"

    # Load config file if specified
    if [[ -n "$config_file" ]]; then
        load_config_file "$config_file" || exit $EXIT_ERROR
    fi

    # Validate configuration
    validate_config || exit $EXIT_ERROR

    # Check dependencies
    check_dependencies || exit $EXIT_ERROR

    # Setup signal handlers
    setup_signal_handlers

    # Write PID file
    write_pid_file

    # Print banner
    print_banner

    # Start monitoring
    monitor_loop
}

# Run main function
main "$@"
