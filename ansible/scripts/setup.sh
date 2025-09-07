#!/bin/bash
# Initial Ansible setup script for Hetzner control node
set -euo pipefail

echo "=== Ansible Control Node Setup ==="
echo "This script should be run on Hetzner (hub node)"
echo

# Check if we're on Hetzner (best-effort, non-fatal)
if [[ "$(hostname)" != *"hetzner"* && "$(hostname)" != *"hq"* ]]; then
    echo "Warning: This doesn't appear to be the Hetzner server (hostname doesn't match '*hetzner*' or '*hq*')."
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Install Ansible if not present
if ! command -v ansible &> /dev/null; then
    echo "Installing Ansible..."
    sudo apt update
    sudo apt install -y ansible ansible-lint python3-pip
    pip3 install --user netaddr jmespath
else
    echo "✓ Ansible already installed: $(ansible --version | head -1)"
fi

# Generate SSH key for Ansible if not present
SSH_KEY="$HOME/.ssh/ansible_ed25519"
if [ ! -f "$SSH_KEY" ]; then
    echo "Generating Ansible SSH key..."
    ssh-keygen -t ed25519 -f "$SSH_KEY" -N "" -C "ansible@hetzner.hq"
    echo "✓ SSH key generated: $SSH_KEY"
else
    echo "✓ Ansible SSH key exists"
fi

# Copy SSH key to laptop if reachable
echo
echo "Attempting to copy SSH key to laptop..."
if tailscale ping -c 1 laptop.hq &> /dev/null; then
    ssh-copy-id -i "$SSH_KEY.pub" verlyn13@laptop.hq || true
    echo "✓ SSH key copied to laptop"
else
    echo "⚠ Laptop not reachable via Tailscale. Copy key manually when available:"
    echo "  ssh-copy-id -i $SSH_KEY.pub verlyn13@laptop.hq"
fi

echo
echo "Testing Ansible connectivity..."
cd "$(dirname "$0")/.."
ansible all -m ping --key-file "$SSH_KEY" || true

echo
echo "=== Setup Complete ==="
echo
echo "Next steps:"
echo "1. Ensure SSH key is copied to all nodes"
echo "2. Run: ansible-playbook playbooks/site.yaml"
echo "3. Check status: ansible all -m setup -a 'filter=ansible_hostname'"
