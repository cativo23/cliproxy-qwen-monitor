#!/usr/bin/env bash
set -euo pipefail

# CLIProxyAPI Qwen Monitor - Quick Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/cativo23/cliproxy-qwen-monitor/main/quickinstall.sh | bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_banner() {
    cat << 'EOF'
   ____                         __  ___            _ __
  / __ \_      _____  ____     /  |/  /___  ____  (_) /_____  _____
 / / / / | /| / / _ \/ __ \   / /|_/ / __ \/ __ \/ / __/ __ \/ ___/
/ /_/ /| |/ |/ /  __/ / / /  / /  / / /_/ / / / / / /_/ /_/ / /
\___\_\|__/|__/\___/_/ /_/  /_/  /_/\____/_/ /_/_/\__/\____/_/
                         Monitor
EOF
}

check_dependencies() {
    local missing=()

    if ! command -v docker &>/dev/null; then
        missing+=("docker")
    fi

    if ! command -v git &>/dev/null; then
        missing+=("git")
    fi

    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Missing dependencies: ${missing[*]}"
        log_info "Install missing dependencies and run again"
        exit 1
    fi

    log_success "All dependencies checked"
}

clone_repository() {
    local install_dir="${HOME}/cliproxy-qwen-monitor"

    if [ -d "$install_dir" ]; then
        log_warning "Directory already exists: $install_dir"
        read -rp "Overwrite? [y/N] " OVERWRITE
        if [[ "${OVERWRITE:-}" =~ ^[Yy]$ ]]; then
            rm -rf "$install_dir"
        else
            log_info "Using existing installation"
            return 0
        fi
    fi

    log_info "Cloning repository..."
    git clone https://github.com/cativo23/cliproxy-qwen-monitor.git "$install_dir"
    log_success "Cloned to $install_dir"
}

show_usage() {
    echo ""
    echo "========================================"
    echo "  Installation Complete!"
    echo "========================================"
    echo ""
    echo "To start the monitor:"
    echo ""
    echo "  1. Navigate to your CLIProxyAPI directory:"
    echo "     cd /path/to/cliproxyapi-dashboard"
    echo ""
    echo "  2. Run the monitor in background:"
    echo "     nohup ~/cliproxy-qwen-monitor/scripts/auto-restart-qwen.sh &"
    echo ""
    echo "  3. Check logs:"
    echo "     tail -f /tmp/cliproxyapi-monitor.log"
    echo ""
    echo "  4. View restart history:"
    echo "     cat /tmp/cliproxyapi-restarts.log"
    echo ""
    echo "To stop the monitor:"
    echo "     pkill -f auto-restart-qwen.sh"
    echo ""
    echo "Documentation: https://github.com/cativo23/cliproxy-qwen-monitor"
    echo ""
}

main() {
    print_banner
    echo ""
    log_info "Starting installation..."
    echo ""

    check_dependencies
    clone_repository
    show_usage

    log_success "Installation complete!"
}

main
