#!/usr/bin/env bash
# Setup SSH access for MacBook in mesh network
# This script helps configure bidirectional SSH access between MacBook and other mesh nodes

set -euo pipefail

MACBOOK_PUBLIC_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICN0hMC4yigFIck+L9op4HPb4AWDaZR+dqc/aRzdywmG jeffreyverlynjohnson@gmail.com"

echo "=== MacBook Mesh SSH Setup ==="
echo ""
echo "This script will help you:"
echo "  1. Enable SSH Remote Login on MacBook"
echo "  2. Distribute MacBook's public key to other nodes"
echo "  3. Collect public keys from other nodes"
echo "  4. Test SSH connectivity"
echo ""

# Step 1: Enable SSH on MacBook
echo "Step 1: Enabling SSH Remote Login on MacBook..."
if sudo systemsetup -getremotelogin 2>/dev/null | grep -q "On"; then
    echo "✓ SSH Remote Login already enabled"
else
    echo "Enabling SSH Remote Login..."
    sudo systemsetup -setremotelogin on
    echo "✓ SSH Remote Login enabled"
fi
echo ""

# Step 2: Show MacBook public key
echo "Step 2: MacBook Public Key"
echo "---"
echo "$MACBOOK_PUBLIC_KEY"
echo "---"
echo ""
echo "You need to add this key to other nodes' ~/.ssh/authorized_keys"
echo ""

# Step 3: Instructions for other nodes
echo "Step 3: On each other mesh node (laptop, WSL, etc.), run:"
echo ""
echo "  echo \"$MACBOOK_PUBLIC_KEY\" >> ~/.ssh/authorized_keys"
echo ""
read -p "Press Enter when you've added the key to other nodes..."
echo ""

# Step 4: Collect keys from other nodes
echo "Step 4: Collecting public keys from other mesh nodes..."
echo ""
echo "Testing connectivity and collecting keys:"
echo ""

# Test Hetzner
echo "Testing hetzner-hq..."
if ssh -o ConnectTimeout=5 -o BatchMode=yes hetzner-hq "cat ~/.ssh/id_ed25519.pub" 2>/dev/null; then
    echo "✓ Hetzner accessible"
else
    echo "⚠ Hetzner not accessible or key not found"
fi
echo ""

# Test Laptop
echo "Testing laptop-hq..."
if ssh -o ConnectTimeout=5 -o BatchMode=yes laptop-hq "cat ~/.ssh/id_ed25519.pub" 2>/dev/null; then
    echo "✓ Laptop accessible"
else
    echo "⚠ Laptop not accessible or key not found"
    echo "  Manual step: On laptop, add MacBook key to ~/.ssh/authorized_keys"
fi
echo ""

# Test WSL
echo "Testing wsl-hq..."
if ssh -o ConnectTimeout=5 -o BatchMode=yes wsl-hq "cat ~/.ssh/id_ed25519.pub" 2>/dev/null; then
    echo "✓ WSL accessible"
else
    echo "⚠ WSL not accessible or key not found"
    echo "  Manual step: On WSL, add MacBook key to ~/.ssh/authorized_keys"
fi
echo ""

# Step 5: Verify MacBook can be accessed
echo "Step 5: Verifying MacBook SSH server..."
if ssh -o ConnectTimeout=5 localhost whoami >/dev/null 2>&1; then
    echo "✓ MacBook SSH server is accessible"
else
    echo "⚠ Cannot SSH to MacBook localhost - check SSH service"
fi
echo ""

echo "=== Summary ==="
echo ""
echo "SSH Configuration files:"
echo "  - Main config: ~/.ssh/config"
echo "  - Mesh config: ~/.ssh/conf.d/mesh.conf"
echo ""
echo "Quick SSH test commands:"
echo "  ssh hetzner-hq whoami"
echo "  ssh laptop-hq whoami"
echo "  ssh wsl-hq whoami"
echo ""
echo "Tailscale mesh status:"
tailscale status
echo ""
echo "Setup complete! Test connectivity with: ssh laptop-hq"
