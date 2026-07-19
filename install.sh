#!/usr/bin/env zsh
# ==============================================================================
# Workspace Manager - Automated Dual-Shell Installer
# ==============================================================================
set -e

REPO_URL="https://github.com/vineethktalasila/workspace-manager.git"
INSTALL_DIR="$HOME/.workspace-manager" # Hidden directory for end-users
CONFIG_FILE="$HOME/.workspace.conf"

echo "=== Installing Workspace Manager ==="

# 1. Dependency Checks
if ! command -v git &> /dev/null; then
    echo "Error: git is required to install Workspace Manager."
    exit 1
fi

if ! command -v zsh &> /dev/null; then
    echo "Error: zsh must be installed on the system (even if it is not your default shell)."
    echo "Please install zsh (e.g., 'sudo apt install zsh') and try again."
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

# 4. Detect Shell and Inject Bindings
USER_SHELL=$(basename "$SHELL")

if [ "$USER_SHELL" = "zsh" ]; then
    RC_FILE="$HOME/.zshrc"
    PLUGIN_FILE="workspace.plugin.zsh"
    echo "-> Zsh environment detected."
elif [ "$USER_SHELL" = "bash" ]; then
    RC_FILE="$HOME/.bashrc"
    PLUGIN_FILE="workspace.plugin.bash"
    echo "-> Bash environment detected."
else
    echo "-> Warning: Unsupported shell ($USER_SHELL). Defaulting to Bash bindings."
    RC_FILE="$HOME/.bashrc"
    PLUGIN_FILE="workspace.plugin.bash"
fi

INJECTION_STRING="source $INSTALL_DIR/$PLUGIN_FILE"

if grep -qF "$INJECTION_STRING" "$RC_FILE"; then
    echo "-> Shell bindings already present in $RC_FILE."
else
    echo "-> Injecting shell bindings into $RC_FILE..."
    echo "\n# Workspace Manager" >> "$RC_FILE"
    echo "$INJECTION_STRING" >> "$RC_FILE"
fi

echo "======================================================"
echo " Installation Complete!"
echo "======================================================"
echo "To finish setup:"
echo "  1. Edit ~/.workspace.conf with your desired paths."
echo "  2. Restart your terminal or run: source $RC_FILE"
echo "  3. Type 'work list' to verify the installation."