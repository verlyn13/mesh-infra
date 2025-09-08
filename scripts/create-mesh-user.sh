#!/bin/bash
# create-mesh-user.sh - Create mesh-ops user with platform-specific configuration
# Usage: ./create-mesh-user.sh [standard|wsl|hub]

set -euo pipefail

# Configuration
MESH_USER="mesh-ops"
MESH_UID=2000
MESH_GID=2000
NODE_TYPE="${1:-standard}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Mesh-Ops User Creation Script ===${NC}"
echo "Node type: $NODE_TYPE"
echo "Creating user: $MESH_USER (UID: $MESH_UID, GID: $MESH_GID)"

# Check if user already exists
if id "$MESH_USER" &>/dev/null; then
    echo -e "${YELLOW}Warning: User $MESH_USER already exists${NC}"
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Exiting..."
        exit 1
    fi
else
    # Create group first
    echo "Creating group $MESH_USER with GID $MESH_GID..."
    sudo groupadd -g $MESH_GID $MESH_USER 2>/dev/null || true

    # Create user with consistent UID/GID
    echo "Creating user $MESH_USER..."
    sudo useradd -m -s /bin/bash \
        -u $MESH_UID -g $MESH_GID \
        -c "Mesh Infrastructure Operations" \
        $MESH_USER
fi

# Platform-specific group assignments
echo "Adding platform-specific groups..."
case $NODE_TYPE in
    wsl)
        echo "  WSL2 configuration (limited sudo, no docker)"
        sudo usermod -aG sudo $MESH_USER 2>/dev/null || \
            sudo usermod -aG wheel $MESH_USER 2>/dev/null || true
        ;;
    hub)
        echo "  Hub configuration (Hetzner Ubuntu)"
        sudo usermod -aG docker,sudo,systemd-journal $MESH_USER 2>/dev/null || true
        ;;
    standard)
        echo "  Standard configuration (Fedora laptop)"
        sudo usermod -aG wheel,systemd-journal $MESH_USER 2>/dev/null || true
        # Add docker group if it exists
        if getent group docker > /dev/null; then
            sudo usermod -aG docker $MESH_USER
        fi
        ;;
    *)
        echo -e "${RED}Error: Unknown node type: $NODE_TYPE${NC}"
        echo "Usage: $0 [standard|wsl|hub]"
        exit 1
        ;;
esac

# Create directory structure
echo "Creating directory structure..."
sudo -u $MESH_USER bash << 'EOF'
mkdir -p ~/.config/{systemd/user,fish,nvim}
mkdir -p ~/.local/{bin,share,state}
mkdir -p ~/Projects/{agents,shared,tools}
mkdir -p ~/Scripts
mkdir -p ~/.ssh
chmod 700 ~/.ssh
EOF

# SSH key propagation
echo "Setting up SSH access..."
if [[ -f ~/.ssh/authorized_keys ]]; then
    echo "  Copying authorized_keys from current user..."
    sudo cp ~/.ssh/authorized_keys /home/$MESH_USER/.ssh/
    sudo chown $MESH_USER:$MESH_USER /home/$MESH_USER/.ssh/authorized_keys
    sudo chmod 600 /home/$MESH_USER/.ssh/authorized_keys
else
    echo -e "${YELLOW}  No authorized_keys found for current user${NC}"
fi

# Create sudoers file based on node type
echo "Configuring sudo permissions..."
SUDOERS_FILE="/etc/sudoers.d/50-mesh-ops"

case $NODE_TYPE in
    wsl)
        cat << 'SUDOEOF' | sudo tee $SUDOERS_FILE > /dev/null
# WSL2 mesh-ops - limited due to corporate restrictions
mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/systemctl --user *
mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/apt update
mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/apt install -y *
mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/tailscale *
mesh-ops ALL=(ALL) NOPASSWD: /bin/loginctl *
# No Docker sudo in WSL2 - will use rootless podman instead
SUDOEOF
        ;;
    hub)
        cat << 'SUDOEOF' | sudo tee $SUDOERS_FILE > /dev/null
# Hub mesh-ops - Hetzner server operations
mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart tailscaled
mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/systemctl status tailscaled
mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/systemctl start tailscaled
mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/systemctl stop tailscaled
mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/tailscale *
mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/apt update
mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/apt install -y *
mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/docker *
mesh-ops ALL=(ALL) NOPASSWD: /usr/sbin/ufw *
SUDOEOF
        ;;
    standard)
        cat << 'SUDOEOF' | sudo tee $SUDOERS_FILE > /dev/null
# Standard mesh-ops - Fedora laptop operations
mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart tailscaled
mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/systemctl status tailscaled
mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/systemctl start tailscaled
mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/systemctl stop tailscaled
mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/tailscale *
mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/dnf install -y *
mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/dnf update -y
mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/docker *
mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/podman *
mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/firewall-cmd *
SUDOEOF
        ;;
esac

# Validate sudoers file
if sudo visudo -c -f $SUDOERS_FILE; then
    echo -e "${GREEN}  Sudoers configuration valid${NC}"
else
    echo -e "${RED}  Error in sudoers configuration!${NC}"
    sudo rm -f $SUDOERS_FILE
    exit 1
fi

# Create initial profile for mesh-ops
echo "Creating initial profile..."
sudo -u $MESH_USER bash << 'PROFILEEOF'
cat > ~/.profile << 'EOF'
# Mesh-Ops User Profile
export USER="mesh-ops"
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/.bun/bin:$HOME/go/bin:$PATH"

# Development environment
export EDITOR="nvim"
export VISUAL="nvim"
export BROWSER="firefox"

# Tool configuration
export UV_CACHE_DIR="$HOME/.cache/uv"
export BUN_INSTALL="$HOME/.bun"
export MISE_DATA_DIR="$HOME/.local/share/mise"

# Mesh-specific
export MESH_NODE_TYPE="__NODE_TYPE__"
export MESH_USER="mesh-ops"

# Source additional configs if they exist
if [ -d ~/.profile.d ]; then
    for f in ~/.profile.d/*.sh; do
        [ -r "$f" ] && . "$f"
    done
fi

# Start in Projects directory
cd ~/Projects 2>/dev/null || true
EOF

# Replace placeholder with actual node type
sed -i "s/__NODE_TYPE__/$NODE_TYPE/" ~/.profile
PROFILEEOF

# Platform-specific initialization
if [[ "$NODE_TYPE" == "wsl" ]]; then
    echo "Adding WSL2-specific initialization..."
    sudo -u $MESH_USER bash << 'WSLEOF'
mkdir -p ~/.profile.d
cat > ~/.profile.d/wsl-init.sh << 'EOF'
#!/bin/bash
# WSL2-specific initialization

# Start userspace services if not running
if ! pgrep -u $USER tailscaled > /dev/null; then
    echo "Starting Tailscale in userspace mode..."
    tailscaled --tun=userspace-networking --socket=~/.tailscale/tailscaled.sock 2>/dev/null &
fi

# Fix WSL2 DNS if needed
if ! nslookup google.com >/dev/null 2>&1; then
    echo "Fixing WSL2 DNS..."
    echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf > /dev/null
fi

# Set Windows interop paths if Chrome exists
if [ -f "/mnt/c/Program Files/Google/Chrome/Application/chrome.exe" ]; then
    export BROWSER="/mnt/c/Program Files/Google/Chrome/Application/chrome.exe"
fi

# Enable systemd user sessions
export XDG_RUNTIME_DIR="/run/user/$UID"
if [ ! -d "$XDG_RUNTIME_DIR" ]; then
    sudo mkdir -p "$XDG_RUNTIME_DIR"
    sudo chown $USER:$USER "$XDG_RUNTIME_DIR"
    sudo chmod 700 "$XDG_RUNTIME_DIR"
fi
EOF
chmod +x ~/.profile.d/wsl-init.sh
WSLEOF
fi

# Verification
echo ""
echo -e "${GREEN}=== Setup Complete ===${NC}"
echo ""
echo "User created: $MESH_USER"
echo "Home directory: /home/$MESH_USER"
echo "Node type: $NODE_TYPE"
echo ""
echo "To switch to mesh-ops user:"
echo "  sudo su - $MESH_USER"
echo ""
echo "To test SSH access:"
echo "  ssh $MESH_USER@localhost"
echo ""

# Quick validation
if sudo su - $MESH_USER -c 'echo "✅ User shell access working"'; then
    echo -e "${GREEN}✅ Basic validation passed${NC}"
else
    echo -e "${RED}❌ User shell access failed${NC}"
    exit 1
fi