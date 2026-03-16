#===============================================================================
# Bash completion for qwen-monitor (auto-restart-qwen.sh)
#===============================================================================
# Install:
#   sudo cp qwen-monitor.bash /etc/bash_completion.d/
#   source /etc/bash_completion.d/qwen-monitor.bash
#
# Or add to ~/.bashrc:
#   source /path/to/qwen-monitor.bash
#===============================================================================

_qwen_monitor() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    opts="-i -c -n -f -m -r -C -v -q -h -V --interval --cooldown --container --compose-file --monitor-log --restart-log --config --verbose --quiet --help --version"

    case "${prev}" in
        -i|--interval)
            COMPREPLY=($(compgen -W "1 2 5 10 15 30 60" -- "${cur}"))
            return 0
            ;;
        -c|--cooldown)
            COMPREPLY=($(compgen -W "5 10 15 20 30 60" -- "${cur}"))
            return 0
            ;;
        -n|--container)
            COMPREPLY=($(compgen -W "$(docker ps --format '{{.Names}}' 2>/dev/null)" -- "${cur}"))
            return 0
            ;;
        -f|--compose-file)
            COMPREPLY=($(compgen -f -X '!*.yml' -- "${cur}"))
            COMPREPLY+=($(compgen -f -X '!*.yaml' -- "${cur}"))
            return 0
            ;;
        -m|--monitor-log|-r|--restart-log|-C|--config)
            COMPREPLY=($(compgen -f -- "${cur}"))
            return 0
            ;;
        *)
            ;;
    esac

    if [[ "${cur}" == -* ]]; then
        COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    else
        COMPREPLY=()
    fi

    return 0
}

complete -F _qwen_monitor auto-restart-qwen.sh qwen-monitor
