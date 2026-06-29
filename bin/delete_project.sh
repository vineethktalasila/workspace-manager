#!/bin/zsh
# ==============================================================================
# Workspace Manager: Project Teardown Engine
# ==============================================================================
set -eo pipefail

PROJECT_NAME=$1

# 1. Parameter Validation
if [ -z "$PROJECT_NAME" ]; then
    echo "Fatal: Project name required." >&2
    echo "Usage: work delete <project_name>"
    exit 1
fi

PROJECT_PATH="$WS_PROJECTS/$PROJECT_NAME"

# 2. State Verification
if [ ! -d "$PROJECT_PATH" ]; then
    echo "Fatal: Local project directory '$PROJECT_PATH' does not exist." >&2
    exit 1
fi

# 3. Fail-Safe Confirmation Protocol
echo "======================================================"
echo "DANGER: You are initiating a dual-target destruction."
echo "Target: $PROJECT_NAME"
echo "This will permanently purge the local directory AND"
echo "the remote GitHub repository. This cannot be undone."
echo "======================================================"
echo -n "To proceed, type the exact project name: "
read -r CONFIRMATION

if [ "$CONFIRMATION" != "$PROJECT_NAME" ]; then
    echo "Abort: String mismatch. Project retained."
    exit 0
fi

echo "Initiating teardown sequence..."

# 4. Remote API Destruction
if command -v gh &> /dev/null; then
    echo "Calling GitHub API to destroy remote origin..."
    # Temporarily disable pipefail so the script doesn't crash if the remote is already gone
    set +e 
    gh repo delete "$PROJECT_NAME" --yes
    if [ $? -eq 0 ]; then
        echo "[Success] Remote GitHub repository purged."
    else
        echo "[Warning] GitHub API failed. The remote may not exist, or gh lacks deletion scopes."
    fi
    set -e
else
    echo "[Warning] GitHub CLI (gh) not found. Skipping remote teardown."
fi

# 5. Local File System & Environment Destruction
if command -v conda &> /dev/null; then
    echo "Purging isolated Conda environment..."
    eval "$(conda shell.zsh hook)"
    
    set +e # Don't crash if Conda environment doesn't exist
    conda remove --name "$PROJECT_NAME" --all -y
    set -e
    
    ENV_PATH="$WS_CONDA_BASE/envs/$PROJECT_NAME"
    if [ -d "$ENV_PATH" ]; then
        echo "[Warning] Forcing manual unlink of environment directory..."
        rm -rf "$ENV_PATH"
    fi
    echo "[Success] Conda environment purged."
fi

echo "Unlinking local directory..."
rm -rf "$PROJECT_PATH"
echo "[Success] Local directory purged."

echo "=== Deletion Complete ==="
