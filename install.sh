#!/bin/zsh
# ==============================================================================
# Workspace Manager - Automated Installer
# ==============================================================================
set -e

REPO_URL="https://github.com/vineethktalasila/workspace-manager.git"
INSTALL_DIR="$HOME/.workspace-manager" # Hidden directory for end-users
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
    echo "-> Updating existing installation at $INSTALL_DIR..."
    git -C "$INSTALL_DIR" pull origin main
else
    echo "-> Cloning repository to hidden directory $INSTALL_DIR..."
    git clone "$REPO_URL" "$INSTALL_DIR"
fi

# 3. Provision Configuration
if [ -f "$CONFIG_FILE" ]; then
    echo "-> Existing ~/.workspace.conf found. Skipping template overwrite."
    # Failsafe: Ensure legacy users get the core dir variable
    if ! grep -q "WS_CORE_DIR" "$CONFIG_FILE"; then
        echo "export WS_CORE_DIR=\"$INSTALL_DIR\"" >> "$CONFIG_FILE"
    fi
else
    echo "-> Provisioning default ~/.workspace.conf..."
    cp "$INSTALL_DIR/workspace.conf.template" "$CONFIG_FILE"
    
    # Automatically wire the core path into the user's new config
    echo "\n# Core System Path (Do not change)" >> "$CONFIG_FILE"
    echo "export WS_CORE_DIR=\"$INSTALL_DIR\"" >> "$CONFIG_FILE"
    
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
echo "  3. Type 'work list' to verify the installation."