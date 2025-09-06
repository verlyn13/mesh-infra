#!/bin/bash
set -euo pipefail

echo "=== Day 1 Mesh Infrastructure Setup ==="
echo

# Check which node we're on
HOSTNAME=$(hostname)
echo "Detected hostname: $HOSTNAME"

case "$HOSTNAME" in
  "docker-cx32-prod")
    echo "→ Configuring Hetzner hub node..."
    NODE="hetzner"
    ;;
  "fedora-top")
    echo "→ Configuring Fedora laptop..."
    NODE="laptop"
    ;;
  "fedora-wsl")
    echo "→ Configuring WSL node..."
    NODE="wsl"
    ;;
  *)
    echo "Unknown hostname. Please set NODE manually."
    exit 1
    ;;
esac

# Install Tailscale
if ! command -v tailscale &> /dev/null; then
  echo "Installing Tailscale..."
  curl -fsSL https://tailscale.com/install.sh | sh
else
  echo "✓ Tailscale already installed"
fi

# Configure based on node role
case "$NODE" in
  "hetzner")
    echo "Starting Tailscale as hub..."
    sudo tailscale up \
      --advertise-exit-node \
      --advertise-routes=172.20.0.0/16 \
      --hostname=hetzner-hq \
      --accept-dns=false
    
    # Create WireGuard backup keys
    if [ ! -f infra/backup/wg/hetzner.key ]; then
      echo "Generating WireGuard backup keys..."
      mkdir -p infra/backup/wg
      wg genkey | tee infra/backup/wg/hetzner.key | wg pubkey > infra/backup/wg/hetzner.pub
      chmod 600 infra/backup/wg/hetzner.key
    fi
    ;;
    
  "laptop")
    echo "Starting Tailscale as workstation..."
    sudo tailscale up \
      --accept-routes \
      --hostname=laptop-hq \
      --accept-dns=true
    ;;
    
  "wsl")
    echo "Starting Tailscale in WSL..."
    # WSL-specific: may need to start tailscaled manually
    if ! pgrep tailscaled > /dev/null; then
      sudo tailscaled --tun=userspace-networking &
      sleep 2
    fi
    sudo tailscale up \
      --accept-routes \
      --hostname=wsl-hq \
      --accept-dns=true
    ;;
esac

echo
echo "✓ Day 1 initialization complete for $NODE"
echo
echo "Next steps:"
echo "1. Verify connectivity: tailscale status"
echo "2. Test mesh: ping other nodes"
echo "3. Create escape hatches: make escape-hatch"