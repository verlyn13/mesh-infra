#!/bin/bash
# Test mesh network connectivity between nodes

set -euo pipefail

echo "=== Mesh Network Connectivity Test ==="
echo

# Check if Tailscale is installed
if ! command -v tailscale &> /dev/null; then
    echo "❌ Tailscale not installed"
    echo "Run 'make init-day1' first"
    exit 1
fi

# Check Tailscale status
echo "Checking Tailscale status..."
if ! tailscale status &> /dev/null; then
    echo "❌ Tailscale not running"
    exit 1
fi

echo "✓ Tailscale is running"
echo

# Show current node info
echo "Current node:"
tailscale status --self --peers=false

echo
echo "Testing connectivity to mesh nodes..."

# Test each node
for node in hetzner-hq laptop-hq wsl-hq; do
    echo -n "Testing $node... "
    if tailscale ping -c 1 "$node" &> /dev/null; then
        echo "✓ reachable"
    else
        echo "✗ unreachable"
    fi
done

echo
echo "Mesh network test complete"