#!/bin/zsh
# ==============================================================================
# Workspace Manager: Project Scaffolding Engine
# ==============================================================================
set -eo pipefail # Fail fast on errors

FLAT_MODE=0
PUBLISH_MODE=0
CLONE_MODE=0
VISIBILITY="--private"
PROJECT_NAME=""
REMOTE_URL=""

# 1. Parse Arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --clone)   CLONE_MODE=1; REMOTE_URL="$2"; shift 2 ;;
        --flat)    FLAT_MODE=1; shift ;;
        --publish) PUBLISH_MODE=1; shift ;;
        --public)  VISIBILITY="--public"; shift ;;
        *)
            if [ -z "$PROJECT_NAME" ]; then PROJECT_NAME="$1"
            elif [ -z "$REMOTE_URL" ]; then REMOTE_URL="$1" fi
            shift ;;
    esac
done

if [ -z "$PROJECT_NAME" ] && [ "$CLONE_MODE" -eq 0 ]; then
    echo "Fatal: Project name required." >&2; exit 1
fi

# 2. Configure Local Git Identity & SSH
configure_local_git() {
    local target_repo="$1"
    if [[ -n "$WS_GIT_USER" && "$WS_GIT_USER" != "Your Name" ]]; then
        git -C "$target_repo" config --local user.name "$WS_GIT_USER"
    fi
    if [[ -n "$WS_GIT_EMAIL" && "$WS_GIT_EMAIL" != "your.email@example.com" ]]; then
        git -C "$target_repo" config --local user.email "$WS_GIT_EMAIL"
    fi
    if [[ -n "$WS_SSH_KEY" && -f "$WS_SSH_KEY" ]]; then
        git -C "$target_repo" config --local core.sshCommand "ssh -i $WS_SSH_KEY -F /dev/null"
    fi
}

# Apply global SSH override for the script execution if key is present
if [[ -n "$WS_SSH_KEY" && -f "$WS_SSH_KEY" ]]; then
    export GIT_SSH_COMMAND="ssh -i $WS_SSH_KEY -F /dev/null"
fi

PROJECT_PATH="$WS_PROJECTS/$PROJECT_NAME"
if [ -d "$PROJECT_PATH" ]; then
    echo "Fatal: Directory already exists at $PROJECT_PATH" >&2; exit 1
fi

# ------------------------------------------------------------------------------
# Branch A: Secure Clone Architecture
# ------------------------------------------------------------------------------
if [ "$CLONE_MODE" -eq 1 ]; then
    if [ -z "$REMOTE_URL" ]; then echo "Fatal: Remote URL required for cloning." >&2; exit 1; fi
    echo "=== Cloning Remote Repository: $PROJECT_NAME ==="
    git clone "$REMOTE_URL" "$PROJECT_PATH"
    configure_local_git "$PROJECT_PATH"
    echo "=== Clone Complete ==="
    exit 0
fi

# ------------------------------------------------------------------------------
# Branch B: Standard Scaffolding
# ------------------------------------------------------------------------------
echo "=== Initializing Workspace: $PROJECT_NAME ==="
mkdir -p "$PROJECT_PATH"

trap 'echo "Error encountered. Rolling back..."; rm -rf "$PROJECT_PATH"; exit 1' ERR

# Conda Provisioning (Dynamic checks)
if command -v conda &> /dev/null; then
    echo "Provisioning isolated Conda environment: $PROJECT_NAME..."
    eval "$(conda shell.zsh hook)"
    conda create --name "$PROJECT_NAME" --clone base -y
else
    echo "Notice: Conda executable not detected. Skipping environment provisioning."
fi

# Topology Scaffolding
if [ "$FLAT_MODE" -eq 0 ]; then
    echo "Building standardized directory tree..."
    mkdir -p "$PROJECT_PATH"/{data/raw,data/processed,notebooks,src,models,tests}
    touch "$PROJECT_PATH"/{data/raw,data/processed,models}/.gitkeep
fi

# Git Ignore Generation
cat << 'EOF' > "$PROJECT_PATH/.gitignore"
.env
.venv
env/
venv/
.ipynb_checkpoints/
data/raw/*
data/processed/*
models/*.pt
models/*.h5
models/*.pkl
*.csv
*.parquet
*.dat
__pycache__/
*.py[cod]
.DS_Store
EOF

# Initialize Git
git -C "$PROJECT_PATH" init
configure_local_git "$PROJECT_PATH"

echo "# $PROJECT_NAME" > "$PROJECT_PATH/README.md"
echo "Project environment initialized." >> "$PROJECT_PATH/README.md"

# VS Code IDE Configuration
mkdir -p "$PROJECT_PATH/.vscode"
cat << EOF > "$PROJECT_PATH/.vscode/settings.json"
{
    "python.defaultInterpreterPath": "$WS_CONDA_BASE/envs/$PROJECT_NAME/bin/python",
    "terminal.integrated.env.osx": {
        "PATH": "$WS_CONDA_BASE/bin:\${env:PATH}"
    },
    "python.terminal.activateEnvironment": false,
    "terminal.integrated.profiles.osx": {
        "zsh (Conda)": {
            "path": "zsh",
            "args": ["-c", "eval \\\"\\$(conda shell.zsh hook)\\\"; conda activate $PROJECT_NAME; exec zsh"]
        }
    },
    "terminal.integrated.defaultProfile.osx": "zsh (Conda)"
}
EOF

# Stage and Commit
git -C "$PROJECT_PATH" add .gitignore README.md .vscode/
if [ "$FLAT_MODE" -eq 0 ]; then git -C "$PROJECT_PATH" add data/ models/; fi
git -C "$PROJECT_PATH" commit -m "Initial commit: Repository scaffold with IDE bindings"

# Remote Publishing
if [ "$PUBLISH_MODE" -eq 1 ] && command -v gh &> /dev/null; then
    echo "Provisioning remote repository via GitHub API ($VISIBILITY)..."
    cd "$PROJECT_PATH"
    gh repo create "$PROJECT_NAME" $VISIBILITY --source="." --remote=origin
    git push -u origin HEAD
elif [ -n "$REMOTE_URL" ]; then
    echo "Binding to remote origin: $REMOTE_URL"
    git -C "$PROJECT_PATH" remote add origin "$REMOTE_URL"
fi

echo "=== Initialization Complete ==="
echo "Navigate to workspace: cd $PROJECT_PATH"
