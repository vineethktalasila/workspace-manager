#!/bin/zsh
# ==============================================================================
# Workspace Manager - Automated Installer
# ==============================================================================

set -e # Exit immediately if a command exits with a non-zero status.

# Define variables
REPO_URL="https://github.com/vineethktalasila/workspace-manager.git"
INSTALL_DIR="$HOME/work/projects/workspace-manager"
CONFIG_FILE="$HOME/.workspace.conf"
ZSHRC="$HOME/.zshrc"

echo "=== Installing Workspace Manager ==="

# 1. Dependency Checks
if ! command -v git &> /dev/null; then
    echo "Error: git is required to install Workspace Manager."
    exit 1
fi

# 2. Clone or Update the Repository
if [ -d "$INSTALL_DIR" ]; then
    echo "-> Workspace Manager is already installed at $INSTALL_DIR."
    echo "-> Pulling latest updates..."
    git -C "$INSTALL_DIR" pull origin main
else
    echo "-> Cloning repository to $INSTALL_DIR..."
    mkdir -p "$HOME/work/projects"
    git clone "$REPO_URL" "$INSTALL_DIR"
fi

# 3. Setup Configuration Template
if [ -f "$CONFIG_FILE" ]; then
    echo "-> Existing ~/.workspace.conf found. Skipping template copy."
else
    echo "-> Provisioning default ~/.workspace.conf template..."
    cp "$INSTALL_DIR/workspace.conf.template" "$CONFIG_FILE"
    echo "-> IMPORTANT: Please review and update ~/.workspace.conf with your personal details."
fi

# 4. Inject Zsh Bindings
INJECTION_STRING="source $INSTALL_DIR/workspace.plugin.zsh"

if grep -qF "$INJECTION_STRING" "$ZSHRC"; then
    echo "-> Zsh bindings already present in ~/.zshrc."
else
    echo "-> Injecting Zsh bindings into ~/.zshrc..."
    echo "\n# Workspace Manager" >> "$ZSHRC"
    echo "$INJECTION_STRING" >> "$ZSHRC"
fi

echo "======================================================"
echo " Installation Complete!"
echo "======================================================"
echo "To finish setup:"
echo "  1. Edit ~/.workspace.conf with your Git and SSD paths."
echo "  2. Restart your terminal or run: source ~/.zshrc"
echo "  3. Type 'work --help' to get started."
