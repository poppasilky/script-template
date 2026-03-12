#!/bin/bash
#
# setup-env.sh - Environment Tethering & Permission Sync
#
# DESCRIPTION:
#   Configures the user's shell environment by tethering the repository
#   to ~/.bashrc and ensuring all lab scripts are executable. This script
#   is designed to be idempotent and portable across different machines.
#
# USAGE:
#   ./.devcontainer/setup-env.sh
#
# ----------------------------------------------------------------------

# Capture the absolute path of the repository
REPO_DIR=$(pwd)

echo "--- 🛰️  Configuring Lab Workspace ---"

#######################################
# Injects the portable REPO_ROOT and PATH logic into ~/.bashrc.
#######################################
tether_bashrc() {
    local tether_block
    
    # This block only activates if the specific REPO_DIR exists on the system.
    tether_block=$(cat <<EOF
# --- Lab Environment Setup (Added $(date +'%Y-%m-%d')) ---
if [ -d "$REPO_DIR" ]; then
    export REPO_ROOT="$REPO_DIR"
    export PATH="\$PATH:\$REPO_ROOT/bin"
    # Source the repo-local .bashrc for custom prompts and aliases
    [ -f "\$REPO_ROOT/.bashrc" ] && source "\$REPO_ROOT/.bashrc"
fi
# -------------------------------------------------------
EOF
)

    # Prevent duplicate entries in ~/.bashrc
    if ! grep -q "REPO_ROOT=\"$REPO_DIR\"" ~/.bashrc; then
        echo "$tether_block" >> ~/.bashrc
        echo "✅ Success: Repository tethered to ~/.bashrc"
    else
        echo "ℹ️  System: ~/.bashrc is already configured."
    fi
}

#######################################
# Synchronizes permissions for the entire bin/ directory.
#######################################
sync_bin_permissions() {
    echo "🔧 Synchronizing script permissions..."
    
    if [ -d "$REPO_DIR/bin" ]; then
        # Ensure every script in bin is ready to run
        chmod ug+x "$REPO_DIR/bin/"*.sh
        echo "✅ Success: All scripts in bin/ are now executable."
    else
        echo "⚠️  Warning: bin/ directory not found."
    fi
}

# --- Execution ---

tether_bashrc
sync_bin_permissions

echo "--- ✅ Workspace Setup Complete ---"
