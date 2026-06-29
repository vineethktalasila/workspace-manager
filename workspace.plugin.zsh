# ==============================================================================
# Workspace Manager - Zsh Plugin Integration
# ==============================================================================

# Ensure config is loaded
if [[ -f "$HOME/.workspace.conf" ]]; then
    source "$HOME/.workspace.conf"
fi

# The main shell function interceptor
work() {
    local cmd=$1
    shift # Remove the command from the argument list
    
    case "$cmd" in
        start)
            source "$WS_PROJECTS/workspace-manager/bin/start.zsh" "$@"
            ;;
        stop)
            source "$WS_PROJECTS/workspace-manager/bin/stop.zsh" "$@"
            ;;
        change)
            echo "=== Transitioning Workspace Topology ==="
            source "$WS_PROJECTS/workspace-manager/bin/stop.zsh"
            source "$WS_PROJECTS/workspace-manager/bin/start.zsh" "$@"
            ;;
        *)
            # Pass all other commands (new, delete, list, etc.) to the isolated binary router
            "$WS_PROJECTS/workspace-manager/bin/work" "$cmd" "$@"
            ;;
    esac
}

# Workspace Autocomplete
_work_project_completions() {
    if [[ -d "$WS_PROJECTS" ]]; then
        local projects=("$WS_PROJECTS"/*(/N:t))
        compadd -a projects
    fi
}

compdef _work_project_completions work
