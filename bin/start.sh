#!/usr/bin/env zsh
# ------------------------------------------------------------------------------
# Script: start.zsh
# Description:
#   Activates a selected workspace by optionally prompting for project choice,
#   activating its matching Conda environment, changing to the project
#   directory, and synchronizing Git state from origin (and upstream if present).
#   This script is intended to be sourced from workspace.plugin.zsh.
#
# Global Variables Required:
#   WS_PROJECTS   - Base directory containing managed project folders.
#   WS_CONDA_BASE - Conda base path used to discover matching environments.
#   WS_SSH_KEY    - Optional SSH private key path for Git fetch/pull operations.
#
# Arguments:
#   $1 - Optional workspace/project name to activate.
#
# Side Effects:
#   - Changes current shell directory (cd) to the selected project.
#   - Activates Conda environment in the current shell (if conda exists).
#   - Performs network Git operations (fetch, pull --rebase, optional merge).
#   - May write merge commits when upstream auto-merge succeeds.
# ------------------------------------------------------------------------------

REQUESTED_ENV=$1
SELECTED_ENV=""

# 1. Dynamically Discover and Route Environment
if [[ -n "$REQUESTED_ENV" && -d "$WS_PROJECTS/$REQUESTED_ENV" ]]; then
    SELECTED_ENV="$REQUESTED_ENV"
else
    echo "=== Select a Workspace ==="
    envs=()
    for dir in "$WS_PROJECTS"/*/; do
        if [ -d "$dir" ]; then
            env_name=$(basename "$dir")
            # Only list it if there is a matching Conda environment
            if [ -d "$WS_CONDA_BASE/envs/$env_name" ]; then
                envs+=("$env_name")
            fi
        fi
    done

    PS3="Enter the number to activate: "
    select SELECTED_ENV in "${envs[@]}"; do
        if [[ -n "$SELECTED_ENV" ]]; then break; fi
    done
fi

if [[ -z "$SELECTED_ENV" ]]; then
    echo "Abort: No workspace selected."
    return 1
fi

# 2. Activate Conda & Route Directory
if command -v conda &> /dev/null; then
    eval "$(conda shell.zsh hook)"
    conda activate "$SELECTED_ENV"
fi

cd "$WS_PROJECTS/$SELECTED_ENV" || return 1

# ---> NEW LINE GOES HERE <---
export WS_ACTIVE_PROJECT="$SELECTED_ENV"

echo "-> Activated ($SELECTED_ENV) at $(pwd)"
echo "=================================="

# 3. Automate Git Syncing (Targeted)
if [ -d ".git" ] && git remote | grep -q 'origin'; then
    echo "Updating: $SELECTED_ENV..."
    ACTIVE_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    
    # Apply SSH config if available
    if [[ -n "$WS_SSH_KEY" && -f "$WS_SSH_KEY" ]]; then
        export GIT_SSH_COMMAND="ssh -i $WS_SSH_KEY -F /dev/null"
    fi
    
    echo " -> Pulling personal changes from origin..."
    git fetch origin
    git pull --rebase origin "$ACTIVE_BRANCH" 2>&1
    
    if git remote | grep -q 'upstream'; then
        echo " -> Checking for upstream updates from original creator..."
        git fetch upstream
        if ! git merge "upstream/$ACTIVE_BRANCH" -m "Auto-merge upstream updates at startup"; then
            echo " -> Fatal: Merge conflict detected! Aborting auto-merge."
            git merge --abort
        else
            echo " -> Upstream updates merged successfully."
        fi
    fi
    echo "-> Sync complete."
else
    echo "Notice: Workspace is local-only or not a Git repository."
fi
echo "=================================="
