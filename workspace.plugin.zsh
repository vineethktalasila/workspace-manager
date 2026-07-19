# ==============================================================================
# Workspace Manager - Zsh Plugin Integration
# ==============================================================================

# Ensure config is loaded
if [[ -f "$HOME/.workspace.conf" ]]; then
    source "$HOME/.workspace.conf"
fi

# A hidden command to hot-reload the workspace manager without restarting the terminal
alias work-reload='source ~/work/projects/workspace-manager/workspace.plugin.zsh && \
                   unfunction _work 2>/dev/null; \
                   autoload -Uz compinit && compinit && \
                   echo "Workspace Manager hot-reloaded successfully."'
# -----------------------

# The main shell function interceptor
work() {
    local cmd=$1
    shift # Remove the command from the argument list
    
    case "$cmd" in
        start)
            source "$WS_CORE_DIR/bin/start.sh" "$@"
            ;;
        stop)
            source "$WS_CORE_DIR/bin/stop.sh" "$@"
            ;;
        change)
            echo "=== Transitioning Workspace Topology ==="
            source "$WS_CORE_DIR/bin/stop.sh"
            source "$WS_CORE_DIR/bin/start.sh" "$@"
            ;;
        *)
            # Pass all other commands (new, delete, list, etc.) to the isolated binary router
            "$WS_CORE_DIR/bin/work" "$cmd" "$@"
            ;;
    esac
}

# Workspace Autocomplete
_work() {
    local -a subcommands
    subcommands=(
        'start:Start a workspace project'
        'stop:Stop the current workspace project'
        'change:Switch to a different workspace project'
        'delete:Delete a workspace project'
        'new:Create a new workspace project'
        'list:List available workspace projects'
        'config:Manage workspace configuration settings'
    )

    # First positional argument: the subcommand itself
    if (( CURRENT == 2 )); then
        _describe -t commands 'work subcommand' subcommands
        return
    fi

    # Only offer project name completion for these subcommands
    case "${words[2]}" in
        start|change|stop|delete)
            if [[ -d "$WS_PROJECTS" ]]; then
                local -a projects
                projects=("$WS_PROJECTS"/*(/N:t))
                compadd -a projects
            fi
            ;;
    esac
}

compdef _work work
