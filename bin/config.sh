#!/usr/bin/env zsh
# ==============================================================================
# Script: config.sh
# Description: Manages the Workspace Manager configuration file.
# ==============================================================================

CONFIG_FILE="$HOME/.workspace.conf"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Fatal: Configuration file not found at $CONFIG_FILE" >&2
    exit 1
fi

SUBCOMMAND=$1
shift

case "$SUBCOMMAND" in
    list)
        echo "=== Workspace Configuration ($CONFIG_FILE) ==="
            
        printf "\033[1mWS_HOME\033[0m: %s\n" "${WS_HOME:-<Not Set>}"
        echo "  -> Root workspace directory"
            
        printf "\n\033[1mWS_PROJECTS\033[0m: %s\n" "${WS_PROJECTS:-<Not Set>}"
        echo "  -> Parent directory containing all managed project folders"
            
        printf "\n\033[1mWS_CONDA_BASE\033[0m: %s\n" "${WS_CONDA_BASE:-<Not Set>}"
        echo "  -> Base directory where Conda environments are managed"
            
        printf "\n\033[1mWS_GIT_USER\033[0m: %s\n" "${WS_GIT_USER:-<Not Set>}"
        echo "  -> Per-project Git user.name applied during cloning/creation"
        
        printf "\n\033[1mWS_GIT_EMAIL\033[0m: %s\n" "${WS_GIT_EMAIL:-<Not Set>}"
        echo "  -> Per-project Git user.email applied during cloning/creation"
            
        printf "\n\033[1mWS_SSH_KEY\033[0m: %s\n" "${WS_SSH_KEY:-<Not Set>}"
        echo "  -> Optional SSH private key path for Git operations"
            
        printf "\n\033[1mWS_CORE_DIR\033[0m: %s\n" "${WS_CORE_DIR:-<Not Set>}"
        echo "  -> (Auto-managed) Hidden path where CLI binaries live"
        echo "=============================================================="
        ;;
    set)
        KEY=$1
        VALUE=$2
        if [[ -z "$KEY" || -z "$VALUE" ]]; then
            echo "Usage: work config set  "
            exit 1
        fi
        
        # Use awk for safe, cross-platform replacement (avoids macOS/Linux sed differences)
        awk -v key="export $KEY=" -v val="export $KEY=\"$VALUE\"" '
        index($0, key) == 1 { print val; found=1; next }
        { print }
        END { if (!found) print val }
        ' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
        
        echo "-> Updated $KEY to \"$VALUE\""
        echo "-> Note: Run 'work-reload' or restart your terminal to apply changes."
        ;;
        
    edit)
        # Safely open in user's preferred editor, fallback to nano
        ${EDITOR:-nano} "$CONFIG_FILE"
        echo "-> Note: Run 'work-reload' or restart your terminal to apply changes."
        ;;
        
    *)
        echo "Usage:"
        echo "  work config list                - View all variables and descriptions"
        echo "  work config set     - Update a specific variable"
        echo "  work config edit                - Open configuration in text editor"
        ;;
esac