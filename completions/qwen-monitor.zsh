#compdef qwen-monitor auto-restart-qwen.sh
#===============================================================================
# Zsh completion for qwen-monitor (auto-restart-qwen.sh)
#===============================================================================
# Install:
#   mkdir -p ~/.zsh/completions
#   cp qwen-monitor.zsh ~/.zsh/completions/_qwen-monitor
#   echo 'fpath=(~/.zsh/completions $fpath)' >> ~/.zshrc
#   echo 'autoload -Uz compinit; compinit' >> ~/.zshrc
#===============================================================================

local -a _qwen_monitor_args
_qwen_monitor_args=(
    '(-i --interval)'{-i,--interval}'[Check interval in seconds]:SECONDS:_values "interval" 1 2 5 10 15 30 60'
    '(-c --cooldown)'{-c,--cooldown}'[Cooldown between restarts]:SECONDS:_values "cooldown" 5 10 15 20 30 60'
    '(-n --container)'{-n,--container}'[Container name]:(->containers)'
    '(-f --compose-file)'{-f,--compose-file}'[Docker Compose file]:FILE:_files -g "*.yml"'
    '(-m --monitor-log)'{-m,--monitor-log}'[Monitor log file]:FILE:_files'
    '(-r --restart-log)'{-r,--restart-log}'[Restart log file]:FILE:_files'
    '(-C --config)'{-C,--config}'[Configuration file]:FILE:_files'
    '(-v --verbose)'{-v,--verbose}'[Enable verbose output]'
    '(-q --quiet)'{-q,--quiet}'[Suppress non-error output]'
    '(-h --help)'{-h,--help}'[Show help message]'
    '(-V --version)'{-V,--version}'[Show version]'
)

local -a _qwen_monitor_containers
_qwen_monitor_containers=($(docker ps --format '{{.Names}}' 2>/dev/null))

local -a _qwen_monitor_compose_files
_qwen_monitor_compose_files=(_files -g "docker-compose*.yml")

_qwen_monitor() {
    local context state line curcontext="$curcontext"

    _arguments -s -S \
        "${_qwen_monitor_args[@]}" \
        && return 0

    if [[ "$state" == "containers" ]]; then
        _values 'container' "${_qwen_monitor_containers[@]}"
    fi

    return 0
}

_qwen_monitor "$@"
