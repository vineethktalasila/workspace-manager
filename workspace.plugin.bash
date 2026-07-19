# ==============================================================================
# Workspace Manager - Bash Plugin Integration
# ==============================================================================

# Ensure config is loaded
if [[ -f "$HOME/.workspace.conf" ]]; then
    source "$HOME/.workspace.conf"
fi

# --- Developer Tools ---
# A hidden command to hot-reload the workspace manager without restarting the terminal
alias work-reload='source "$WS_CORE_DIR/workspace.plugin.bash" && \
                   echo "Workspace Manager hot-reloaded successfully (Bash)."'
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
            # Pass all other commands (new, delete, list, backup) to the isolated binary router
            "$WS_CORE_DIR/bin/work" "$cmd" "$@"
            ;;
    esac
}

# Workspace Autocomplete
_work_bash_autocomplete() {
    local cur prev subcommands projects
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    subcommands="start stop change delete new list backup"

    # If completing the first word (the subcommand)
    if [[ ${COMP_CWORD} -eq 1 ]]; then
        COMPREPLY=( $(compgen -W "${subcommands}" -- "${cur}") )
        return 0
    fi

    # If completing the second word (the project name)
    case "${prev}" in
        start|stop|change|delete)
            if [[ -d "$WS_PROJECTS" ]]; then
                # Standard Bash directory listing, safely stripping the trailing slashes
                projects=$(ls -1p "$WS_PROJECTS" 2>/dev/null | grep '/$' | sed 's/\/$//')
                COMPREPLY=( $(compgen -W "${projects}" -- "${cur}") )
            fi
            ;;
    esac
    return 0
}

# Register the autocomplete function for 'work'
complete -F _work_bash_autocomplete work