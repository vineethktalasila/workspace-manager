#!/bin/zsh
# ==============================================================================
# Script: stop.zsh
# Description: Teardown and sync for the CURRENTLY ACTIVE workspace project.
# ==============================================================================

echo "=== Initiating Workspace Teardown ==="
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# 1. Identify the Active Project via Session Variable
if [[ -z "$WS_ACTIVE_PROJECT" ]]; then
    echo " -> No active workspace project detected in this shell session."
    return 0
fi

PROJECT_NAME="$WS_ACTIVE_PROJECT"
repo="$WS_PROJECTS/$PROJECT_NAME"

# 2. Targeted Synchronization
if [ -d "$repo/.git" ]; then
    echo "Analyzing state of: $PROJECT_NAME"
    
    # Extract Environment Blueprint
    ENV_PATH="$WS_CONDA_BASE/envs/$PROJECT_NAME"
    if [ -d "$ENV_PATH" ] && command -v conda &> /dev/null; then
        conda env export -p "$ENV_PATH" --no-builds > "$repo/environment.yml" 2>/dev/null || true
    fi
    
    # Apply SSH config if available
    if [[ -n "$WS_SSH_KEY" && -f "$WS_SSH_KEY" ]]; then
        export GIT_SSH_COMMAND="ssh -i $WS_SSH_KEY -F /dev/null"
    fi

    # Check for local modifications
    CHANGES=$(git -C "$repo" status --porcelain)
    if [ -n "$CHANGES" ]; then
        echo " -> Modifications detected. Staging changes..."
        git -C "$repo" add .
        git -C "$repo" commit -m "Automated teardown commit: $TIMESTAMP"
        
        if git -C "$repo" remote | grep -q 'origin'; then
            echo " -> Pushing to remote origin..."
            ACTIVE_BRANCH=$(git -C "$repo" rev-parse --abbrev-ref HEAD)
            git -C "$repo" push origin "$ACTIVE_BRANCH" 2>&1
        fi
        echo " -> Sync complete for $PROJECT_NAME."
    else
        echo " -> Working tree is clean. No synchronization required."
    fi
fi

# 3. System Unbinding & Lock Release
if command -v conda &> /dev/null; then
    if [[ -n "$CONDA_SHLVL" ]] && [[ "$CONDA_SHLVL" -gt 0 ]]; then
        while [[ "$CONDA_SHLVL" -gt 0 ]]; do
            PREV_SHLVL="$CONDA_SHLVL"
            conda deactivate 2>/dev/null
            if [[ "$CONDA_SHLVL" -eq "$PREV_SHLVL" ]]; then break; fi
        done
    fi
fi

# 4. Clear Session State and Return Home
unset WS_ACTIVE_PROJECT
cd ~
echo "Workspace detached. Returned to: $(pwd)"
echo "=== Teardown Complete ==="