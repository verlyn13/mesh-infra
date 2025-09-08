#!/bin/bash
# setup-mesh-user-wsl.sh - WSL2-specific mesh-ops user setup
# This script handles the unique requirements of WSL2 environments

set -euo pipefail

# Configuration
MESH_USER="mesh-ops"
MESH_UID=2000
MESH_GID=2000

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== WSL2 Mesh-Ops Setup Script ===${NC}"

# WSL2 detection
if [[ ! -f /proc/sys/fs/binfmt_misc/WSLInterop ]]; then
    echo -e "${RED}Error: This script must be run in WSL2 environment${NC}"
    echo "For non-WSL systems, use create-mesh-user.sh"
    exit 1
fi

echo -e "${GREEN}✓ WSL2 environment detected${NC}"

# Get Windows username for reference
WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r\n' || echo "unknown")
echo "Windows user: $WIN_USER"

# Detect WSL distribution
WSL_DISTRO=$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"')
echo "WSL distribution: $WSL_DISTRO"

# Check for systemd support
if pidof systemd > /dev/null; then
    echo -e "${GREEN}✓ Systemd is running${NC}"
    SYSTEMD_ENABLED=true
else
    echo -e "${YELLOW}⚠ Systemd not detected - user services will be limited${NC}"
    SYSTEMD_ENABLED=false
fi

# Create mesh-ops user
echo ""
echo "Creating mesh-ops user..."

if id "$MESH_USER" &>/dev/null; then
    echo -e "${YELLOW}User $MESH_USER already exists${NC}"
else
    # Create group
    sudo groupadd -g $MESH_GID $MESH_USER 2>/dev/null || true
    
    # Create user without docker group (not available in WSL2)
    sudo useradd -m -s /bin/bash \
        -u $MESH_UID -g $MESH_GID \
        -c "Mesh Infrastructure Operations (WSL2)" \
        $MESH_USER
    
    # Add to appropriate admin group
    if getent group sudo > /dev/null; then
        sudo usermod -aG sudo $MESH_USER
    elif getent group wheel > /dev/null; then
        sudo usermod -aG wheel $MESH_USER
    fi
    
    echo -e "${GREEN}✓ User created${NC}"
fi

# WSL2-specific sudoers configuration
echo "Configuring WSL2-specific sudo permissions..."
cat << 'EOF' | sudo tee /etc/sudoers.d/50-mesh-ops-wsl > /dev/null
# WSL2 mesh-ops - adapted for corporate restrictions
Defaults:mesh-ops !requiretty
Defaults:mesh-ops env_keep += "WSL_DISTRO_NAME WSL_INTEROP"

# Systemd user services (if available)
mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/systemctl --user *
mesh-ops ALL=(ALL) NOPASSWD: /bin/loginctl *

# Package management
mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/apt update
mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/apt install -y *
mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/apt-get update
mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/apt-get install -y *
mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/dnf install -y *
mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/yum install -y *

# Tailscale userspace mode
mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/tailscale *
mesh-ops ALL=(ALL) NOPASSWD: /usr/sbin/tailscaled *

# DNS fixing for WSL2
mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/tee /etc/resolv.conf
mesh-ops ALL=(ALL) NOPASSWD: /bin/chmod * /etc/resolv.conf

# Runtime directory management
mesh-ops ALL=(ALL) NOPASSWD: /bin/mkdir -p /run/user/2000
mesh-ops ALL=(ALL) NOPASSWD: /bin/chown mesh-ops\:mesh-ops /run/user/2000
mesh-ops ALL=(ALL) NOPASSWD: /bin/chmod 700 /run/user/2000
EOF

# Validate sudoers
if sudo visudo -c -f /etc/sudoers.d/50-mesh-ops-wsl; then
    echo -e "${GREEN}✓ Sudoers configuration valid${NC}"
else
    echo -e "${RED}✗ Sudoers configuration invalid!${NC}"
    sudo rm -f /etc/sudoers.d/50-mesh-ops-wsl
    exit 1
fi

# Create WSL2-specific directory structure
echo "Creating WSL2-adapted directory structure..."
sudo -u $MESH_USER bash << 'EOF'
# Standard directories
mkdir -p ~/.config/{systemd/user,fish,nvim}
mkdir -p ~/.local/{bin,share,state}
mkdir -p ~/Projects/{agents,shared,tools}
mkdir -p ~/Scripts
mkdir -p ~/.ssh

# WSL2-specific
mkdir -p ~/.tailscale
mkdir -p ~/.wsl
mkdir -p ~/.profile.d

# Permissions
chmod 700 ~/.ssh ~/.tailscale
EOF

# SSH key setup
echo "Setting up SSH access..."
if [[ -f ~/.ssh/authorized_keys ]]; then
    sudo cp ~/.ssh/authorized_keys /home/$MESH_USER/.ssh/
    sudo chown $MESH_USER:$MESH_USER /home/$MESH_USER/.ssh/authorized_keys
    sudo chmod 600 /home/$MESH_USER/.ssh/authorized_keys
    echo -e "${GREEN}✓ SSH keys copied${NC}"
fi

# Create WSL2-specific profile
echo "Creating WSL2-specific profile..."
sudo -u $MESH_USER bash << 'PROFILEEOF'
cat > ~/.profile << 'EOF'
# Mesh-Ops WSL2 Profile
export USER="mesh-ops"
export MESH_NODE_TYPE="wsl"
export WSL_ENV=true

# Path setup
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/.bun/bin:$HOME/go/bin:$PATH"

# Development tools
export EDITOR="${EDITOR:-vim}"
export VISUAL="${VISUAL:-vim}"

# WSL2 interop
export WSL_DISTRO="$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"')"

# XDG directories for systemd user sessions
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$UID}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# Source additional configs
if [ -d ~/.profile.d ]; then
    for f in ~/.profile.d/*.sh; do
        [ -r "$f" ] && . "$f"
    done
fi

# Start in Projects
cd ~/Projects 2>/dev/null || true
EOF
PROFILEEOF

# Create WSL2 initialization script
echo "Creating WSL2 initialization script..."
sudo -u $MESH_USER bash << 'WSLINITEOF'
cat > ~/.profile.d/wsl-init.sh << 'EOF'
#!/bin/bash
# WSL2 Initialization Script for mesh-ops

# Ensure runtime directory exists
if [ ! -d "$XDG_RUNTIME_DIR" ]; then
    sudo mkdir -p "$XDG_RUNTIME_DIR"
    sudo chown $USER:$USER "$XDG_RUNTIME_DIR"
    sudo chmod 700 "$XDG_RUNTIME_DIR"
fi

# Fix WSL2 DNS issues
fix_wsl_dns() {
    if ! nslookup google.com >/dev/null 2>&1; then
        echo "Fixing WSL2 DNS..."
        echo -e "nameserver 8.8.8.8\nnameserver 8.8.4.4" | sudo tee /etc/resolv.conf > /dev/null
        sudo chmod 644 /etc/resolv.conf
    fi
}

# Start Tailscale in userspace mode if available
start_tailscale_userspace() {
    if command -v tailscaled >/dev/null 2>&1; then
        if ! pgrep -u $USER tailscaled > /dev/null; then
            echo "Starting Tailscale in userspace mode..."
            tailscaled --tun=userspace-networking \
                       --socket=$HOME/.tailscale/tailscaled.sock \
                       --state=$HOME/.tailscale/tailscaled.state \
                       2>/dev/null &
            sleep 2
            
            # Set socket for tailscale CLI
            export TAILSCALE_SOCKET="$HOME/.tailscale/tailscaled.sock"
        fi
    fi
}

# Windows interop setup
setup_windows_interop() {
    # Try to find Chrome
    local chrome_paths=(
        "/mnt/c/Program Files/Google/Chrome/Application/chrome.exe"
        "/mnt/c/Program Files (x86)/Google/Chrome/Application/chrome.exe"
    )
    
    for chrome in "${chrome_paths[@]}"; do
        if [ -f "$chrome" ]; then
            export BROWSER="$chrome"
            break
        fi
    done
    
    # Set up WSL utilities
    export WSLENV="$WSLENV:BROWSER"
}

# WSL2 systemd check
check_systemd() {
    if pidof systemd > /dev/null; then
        # Systemd is running, ensure user instance works
        systemctl --user status > /dev/null 2>&1 || {
            echo "Initializing systemd user instance..."
            sudo loginctl enable-linger $USER
        }
    else
        echo "Note: Systemd not available - some services will be limited"
    fi
}

# Execute initialization functions
fix_wsl_dns
setup_windows_interop
check_systemd
# Uncomment when Tailscale is installed:
# start_tailscale_userspace

# WSL2-specific aliases
alias wsl-ip='ip addr show eth0 | grep -oP "(?<=inet\s)\d+(\.\d+){3}"'
alias win-home='cd /mnt/c/Users/$(/mnt/c/Windows/System32/cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d "\r\n")'
EOF

chmod +x ~/.profile.d/wsl-init.sh
WSLINITEOF

# Create Tailscale userspace setup script
echo "Creating Tailscale userspace setup script..."
sudo -u $MESH_USER bash << 'TAILSCALEEOF'
cat > ~/Scripts/setup-tailscale-userspace.sh << 'EOF'
#!/bin/bash
# Setup Tailscale in userspace mode for WSL2

set -e

echo "Setting up Tailscale in userspace mode..."

# Install Tailscale if not present
if ! command -v tailscale >/dev/null 2>&1; then
    echo "Installing Tailscale..."
    curl -fsSL https://tailscale.com/install.sh | sh
fi

# Create systemd user service (if systemd available)
if pidof systemd > /dev/null; then
    mkdir -p ~/.config/systemd/user
    
    cat > ~/.config/systemd/user/tailscaled.service << 'SYSD'
[Unit]
Description=Tailscale node agent (userspace)
After=network.target

[Service]
Type=simple
ExecStart=/usr/sbin/tailscaled --tun=userspace-networking --socket=%h/.tailscale/tailscaled.sock --state=%h/.tailscale/tailscaled.state
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
SYSD
    
    systemctl --user daemon-reload
    systemctl --user enable tailscaled
    systemctl --user start tailscaled
    
    echo "Tailscale userspace service installed"
else
    echo "Systemd not available - add to ~/.profile.d/wsl-init.sh to start manually"
fi

# Set up environment
echo "export TAILSCALE_SOCKET=\$HOME/.tailscale/tailscaled.sock" >> ~/.profile.d/tailscale.sh

echo "Tailscale userspace setup complete"
echo "To authenticate: tailscale up --operator=\$USER"
EOF

chmod +x ~/Scripts/setup-tailscale-userspace.sh
TAILSCALEEOF

# Create connectivity test script
echo "Creating connectivity test script..."
sudo -u $MESH_USER bash << 'TESTEOF'
cat > ~/Scripts/test-wsl-connectivity.sh << 'EOF'
#!/bin/bash
# Test WSL2 connectivity and environment

echo "=== WSL2 Connectivity Test ==="
echo

# Basic network
echo "1. Basic Network:"
echo -n "  Internet: "
ping -c 1 8.8.8.8 >/dev/null 2>&1 && echo "✓" || echo "✗"
echo -n "  DNS: "
nslookup google.com >/dev/null 2>&1 && echo "✓" || echo "✗"

# WSL2 specific
echo
echo "2. WSL2 Environment:"
echo "  WSL IP: $(ip addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}' || echo 'not found')"
echo "  Windows host: $(cat /etc/resolv.conf | grep nameserver | awk '{print $2}' || echo 'not found')"
echo "  Distro: $WSL_DISTRO_NAME"

# Systemd
echo
echo "3. Systemd Status:"
if pidof systemd > /dev/null; then
    echo "  Systemd: ✓ running"
    systemctl --user status >/dev/null 2>&1 && echo "  User instance: ✓" || echo "  User instance: ✗"
else
    echo "  Systemd: ✗ not running"
fi

# Tailscale (if installed)
echo
echo "4. Tailscale Status:"
if command -v tailscale >/dev/null 2>&1; then
    if [ -S "$HOME/.tailscale/tailscaled.sock" ]; then
        echo "  Socket: ✓ exists"
        TAILSCALE_SOCKET="$HOME/.tailscale/tailscaled.sock" tailscale status >/dev/null 2>&1 && \
            echo "  Status: ✓ running" || echo "  Status: ✗ not running"
    else
        echo "  Socket: ✗ not found"
    fi
else
    echo "  Not installed"
fi

echo
echo "=== Test Complete ==="
EOF

chmod +x ~/Scripts/test-wsl-connectivity.sh
TESTEOF

# Final validation
echo ""
echo -e "${GREEN}=== WSL2 Setup Complete ===${NC}"
echo ""
echo "User: $MESH_USER (UID: $MESH_UID)"
echo "Home: /home/$MESH_USER"
echo "WSL Distro: $WSL_DISTRO"
echo "Systemd: $([[ $SYSTEMD_ENABLED == true ]] && echo "enabled" || echo "disabled")"
echo ""
echo "Next steps:"
echo "1. Switch to mesh-ops user:"
echo "   ${BLUE}sudo su - $MESH_USER${NC}"
echo ""
echo "2. Test WSL2 connectivity:"
echo "   ${BLUE}~/Scripts/test-wsl-connectivity.sh${NC}"
echo ""
echo "3. Set up Tailscale (as mesh-ops):"
echo "   ${BLUE}~/Scripts/setup-tailscale-userspace.sh${NC}"
echo ""

# Quick validation
if sudo su - $MESH_USER -c 'echo "✅ User access verified"'; then
    echo -e "${GREEN}✅ Setup validated successfully${NC}"
else
    echo -e "${RED}❌ User access validation failed${NC}"
    exit 1
fi