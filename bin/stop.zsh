# ------------------------------------------------------------------------------
# Script: stop.zsh
# Description:
#   Performs workspace teardown and backup sync by scanning managed repositories,
#   exporting Conda environment specs, auto-committing/pushing pending changes,
#   deactivating active Conda shells, and returning to the user's home
#   directory. This script is intended to be sourced from workspace.plugin.zsh.
#
# Global Variables Required:
#   WS_PROJECTS   - Base directory containing managed project folders.
#   WS_CONDA_BASE - Conda base path used to export per-project environments.
#   WS_SSH_KEY    - Optional SSH private key path for Git push operations.
#
# Arguments:
#   None.
#
# Side Effects:
#   - Writes/overwrites environment.yml files in managed repositories.
#   - Creates Git commits for dirty repositories.
#   - Pushes commits to remote origin (network side effect).
#   - Deactivates Conda environments in the current shell session.
#   - Changes current shell directory to $HOME.
# ------------------------------------------------------------------------------

echo "=== Initiating Workspace Teardown ==="
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# Apply SSH config if available
if [[ -n "$WS_SSH_KEY" && -f "$WS_SSH_KEY" ]]; then
    export GIT_SSH_COMMAND="ssh -i $WS_SSH_KEY -F /dev/null"
fi

# 1. Automated Git Commits and Pushing (Outbound Only)
for repo in "$WS_PROJECTS"/*/; do
    if [ -d "${repo}.git" ] && git -C "$repo" remote | grep -q 'origin'; then
        PROJECT_NAME=$(basename "$repo")
        echo "Analyzing state of: $PROJECT_NAME"
        
        # Extract Environment Blueprint
        ENV_PATH="$WS_CONDA_BASE/envs/$PROJECT_NAME"
        if [ -d "$ENV_PATH" ] && command -v conda &> /dev/null; then
            conda env export -p "$ENV_PATH" --no-builds > "$repo/environment.yml" 2>/dev/null
        fi
        
        # Check for local modifications
        CHANGES=$(git -C "$repo" status --porcelain)
        if [ -n "$CHANGES" ]; then
            echo " -> Modifications detected. Staging changes..."
            git -C "$repo" add .
            git -C "$repo" commit -m "Automated teardown commit: $TIMESTAMP"
            
            echo " -> Pushing to remote origin (Personal Backup)..."
            ACTIVE_BRANCH=$(git -C "$repo" rev-parse --abbrev-ref HEAD)
            git -C "$repo" push origin "$ACTIVE_BRANCH" 2>&1
            echo "-> Sync complete for $PROJECT_NAME."
        else
            echo " -> Working tree is clean. No synchronization required."
        fi
        echo "----------------------------------------"
    fi
done

# 2. System Unbinding & Lock Release
if command -v conda &> /dev/null; then
    if [[ -n "$CONDA_SHLVL" ]] && [[ "$CONDA_SHLVL" -gt 0 ]]; then
        while [[ "$CONDA_SHLVL" -gt 0 ]]; do
            PREV_SHLVL="$CONDA_SHLVL"
            conda deactivate 2>/dev/null
            if [[ "$CONDA_SHLVL" -eq "$PREV_SHLVL" ]]; then break; fi
        done
    fi
fi

# 3. Return Home safely
cd ~
echo "Workspace detached. Returned to: $(pwd)"
echo "=== Teardown Complete ==="
