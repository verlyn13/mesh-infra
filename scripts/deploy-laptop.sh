#!/bin/bash
# deploy-laptop.sh - Deploy mesh-ops user to laptop-hq (current node)
# This is the second node in the WSL → Laptop → Hetzner deployment sequence

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}=== Mesh-Ops Deployment to Laptop Node ===${NC}"
echo -e "Hostname: $(hostname)"
echo -e "Date: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# Verify we're on the laptop node
if [[ $(hostname -s) != "fedora-top" ]]; then
    echo -e "${YELLOW}Warning: This doesn't appear to be the laptop node (fedora-top)${NC}"
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Deployment cancelled"
        exit 1
    fi
fi

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo -e "${RED}This script should not be run as root${NC}"
   exit 1
fi

echo -e "${BLUE}Step 1: Pre-deployment checks${NC}"
echo ""

# Check Tailscale connectivity
echo -n "Checking Tailscale status: "
if tailscale status > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    echo "Tailscale is not running. Please ensure Tailscale is connected."
    exit 1
fi

# Check connectivity to other nodes
echo "Testing mesh connectivity:"
for node_info in "wsl-fedora-kbc:100.88.131.44" "hetzner-hq:100.84.151.58"; do
    IFS=':' read -r node_name node_ip <<< "$node_info"
    echo -n "  $node_name: "
    if ping -c 1 -W 2 $node_ip > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Reachable${NC}"
    else
        echo -e "${YELLOW}✗ Not reachable${NC}"
    fi
done

echo ""
echo -e "${BLUE}Step 2: Creating mesh-ops user${NC}"
echo ""

# Run the creation script
if [[ -f scripts/create-mesh-user.sh ]]; then
    echo "Running user creation script..."
    bash scripts/create-mesh-user.sh standard
else
    echo -e "${RED}Error: create-mesh-user.sh not found${NC}"
    echo "Please ensure you're in the mesh-infra directory"
    exit 1
fi

echo ""
echo -e "${BLUE}Step 3: Validating deployment${NC}"
echo ""

# Run validation
if [[ -f scripts/validate-mesh-ops.sh ]]; then
    echo "Running validation script..."
    bash scripts/validate-mesh-ops.sh
    VALIDATION_RESULT=$?
else
    echo -e "${YELLOW}Warning: Validation script not found${NC}"
    VALIDATION_RESULT=1
fi

echo ""
echo -e "${BLUE}Step 4: Post-deployment configuration${NC}"
echo ""

# Generate SSH key for mesh-ops if it doesn't exist
echo "Checking SSH keys for mesh-ops..."
if ! sudo test -f /home/mesh-ops/.ssh/id_ed25519; then
    echo "Generating SSH key for mesh-ops..."
    sudo -u mesh-ops ssh-keygen -t ed25519 -f /home/mesh-ops/.ssh/id_ed25519 -N "" -C "mesh-ops@laptop-hq"
    echo -e "${GREEN}✓ SSH key generated${NC}"
else
    echo -e "${GREEN}✓ SSH key already exists${NC}"
fi

# Display the public key
echo ""
echo "mesh-ops public key for laptop-hq:"
echo -e "${YELLOW}"
sudo -u mesh-ops cat /home/mesh-ops/.ssh/id_ed25519.pub
echo -e "${NC}"

# Get WSL node's public key if available
echo ""
echo -e "${BLUE}Step 5: Cross-node SSH setup${NC}"
echo ""
echo "To enable mesh-ops SSH access between nodes, add these keys to authorized_keys:"
echo ""
echo "1. Get WSL node's mesh-ops public key:"
echo "   ${CYAN}ssh wsl-fedora-kbc 'sudo -u mesh-ops cat /home/mesh-ops/.ssh/id_ed25519.pub'${NC}"
echo ""
echo "2. Add it to this node's mesh-ops authorized_keys:"
echo "   ${CYAN}sudo -u mesh-ops bash -c 'cat >> /home/mesh-ops/.ssh/authorized_keys'${NC}"
echo ""
echo "3. Share this node's key with WSL node:"
echo "   Copy the key shown above and add to WSL's mesh-ops authorized_keys"

echo ""
echo -e "${BLUE}=== Deployment Summary ===${NC}"
echo ""

if [[ $VALIDATION_RESULT -eq 0 ]]; then
    echo -e "${GREEN}✅ Deployment successful!${NC}"
    echo ""
    echo "mesh-ops user is ready on laptop-hq"
    echo ""
    echo "Next steps:"
    echo "1. Switch to mesh-ops user: ${CYAN}sudo su - mesh-ops${NC}"
    echo "2. Install development tools: ${CYAN}make mesh-user-bootstrap${NC}"
    echo "3. Configure cross-node SSH access (see above)"
    echo "4. Deploy to hetzner-hq (final node): ${CYAN}ssh hetzner-hq${NC}"
else
    echo -e "${YELLOW}⚠ Deployment completed with warnings${NC}"
    echo ""
    echo "Please review the validation output above and address any issues."
    echo "You can re-run validation with: ${CYAN}make mesh-user-validate${NC}"
fi

echo ""
echo -e "${GREEN}Laptop node (2/3) deployment complete${NC}"
echo "Deployment sequence: WSL ✅ → Laptop ✅ → Hetzner ⏳"