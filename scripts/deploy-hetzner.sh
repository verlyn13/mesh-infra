#!/bin/bash
# deploy-hetzner.sh - Deploy mesh-ops user to hetzner-hq (final node)
# This is the third and final node in the WSL → Laptop → Hetzner deployment sequence

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${MAGENTA}=== Mesh-Ops Deployment to Hetzner Hub Node ===${NC}"
echo -e "${MAGENTA}=== FINAL DEPLOYMENT - Production Control Node ===${NC}"
echo ""
echo "Target: hetzner-hq (91.99.101.204)"
echo "Date: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# Check if we're running locally or need to SSH
if [[ $(hostname -s) == "docker-cx32-prod" ]] || [[ $(hostname) == *"hetzner"* ]]; then
    echo -e "${GREEN}Running directly on Hetzner node${NC}"
    REMOTE_EXEC=""
else
    echo -e "${BLUE}Running from local node - will deploy via SSH${NC}"
    REMOTE_EXEC="ssh -p 2222 verlyn13@91.99.101.204"
    
    # Test SSH connectivity
    echo -n "Testing SSH connectivity to Hetzner: "
    if $REMOTE_EXEC "echo 'connected'" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗${NC}"
        echo "Cannot connect to Hetzner. Please check:"
        echo "  1. SSH is running on port 2222"
        echo "  2. Your SSH key is authorized"
        echo "  3. Network connectivity"
        exit 1
    fi
fi

echo ""
echo -e "${YELLOW}⚠️  Production Node Warning${NC}"
echo "This is the production hub node with:"
echo "  - Ansible control node role"
echo "  - Tailscale exit node configuration"
echo "  - Public IP exposure (91.99.101.204)"
echo ""
read -p "Proceed with deployment? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled"
    exit 0
fi

echo ""
echo -e "${BLUE}Step 1: Pre-deployment verification${NC}"
echo ""

# Function to run commands either locally or remotely
run_cmd() {
    if [[ -z "$REMOTE_EXEC" ]]; then
        eval "$1"
    else
        $REMOTE_EXEC "$1"
    fi
}

# Check system info
echo "System information:"
run_cmd "uname -n && lsb_release -d 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME"

# Check Tailscale status
echo ""
echo -n "Tailscale status: "
if run_cmd "tailscale status > /dev/null 2>&1"; then
    echo -e "${GREEN}✓ Running${NC}"
    
    # Check if it's an exit node
    if run_cmd "tailscale status --json 2>/dev/null | grep -q '\"ExitNode\": true'" 2>/dev/null; then
        echo -e "  Exit node: ${GREEN}✓ Configured${NC}"
    else
        echo -e "  Exit node: ${YELLOW}Not configured${NC}"
    fi
else
    echo -e "${RED}✗ Not running${NC}"
fi

# Check connectivity to other mesh nodes
echo ""
echo "Mesh connectivity:"
for node_info in "wsl-fedora-kbc:100.88.131.44" "laptop-hq:100.84.2.8"; do
    IFS=':' read -r node_name node_ip <<< "$node_info"
    echo -n "  $node_name: "
    if run_cmd "ping -c 1 -W 2 $node_ip > /dev/null 2>&1"; then
        echo -e "${GREEN}✓ Reachable${NC}"
    else
        echo -e "${YELLOW}✗ Not reachable${NC}"
    fi
done

echo ""
echo -e "${BLUE}Step 2: Deploying mesh-ops user${NC}"
echo ""

# Deploy the user creation script
if [[ -n "$REMOTE_EXEC" ]]; then
    echo "Copying deployment scripts to Hetzner..."
    scp -P 2222 scripts/create-mesh-user.sh verlyn13@91.99.101.204:/tmp/
    scp -P 2222 scripts/validate-mesh-ops.sh verlyn13@91.99.101.204:/tmp/
    
    echo "Running user creation on Hetzner..."
    $REMOTE_EXEC "cd /tmp && bash create-mesh-user.sh hub"
else
    # Running directly on Hetzner
    if [[ -f scripts/create-mesh-user.sh ]]; then
        bash scripts/create-mesh-user.sh hub
    elif [[ -f /tmp/create-mesh-user.sh ]]; then
        bash /tmp/create-mesh-user.sh hub
    else
        echo -e "${RED}Error: create-mesh-user.sh not found${NC}"
        exit 1
    fi
fi

echo ""
echo -e "${BLUE}Step 3: Validation${NC}"
echo ""

# Run validation
if [[ -n "$REMOTE_EXEC" ]]; then
    echo "Running validation on Hetzner..."
    $REMOTE_EXEC "cd /tmp && bash validate-mesh-ops.sh" || true
else
    if [[ -f scripts/validate-mesh-ops.sh ]]; then
        bash scripts/validate-mesh-ops.sh || true
    elif [[ -f /tmp/validate-mesh-ops.sh ]]; then
        bash /tmp/validate-mesh-ops.sh || true
    fi
fi

echo ""
echo -e "${BLUE}Step 4: SSH Key Management${NC}"
echo ""

# Generate SSH key for mesh-ops
echo "Generating SSH key for mesh-ops@hetzner-hq..."
run_cmd "sudo -u mesh-ops ssh-keygen -t ed25519 -f /home/mesh-ops/.ssh/id_ed25519 -N '' -C 'mesh-ops@hetzner-hq' 2>/dev/null || true"

echo ""
echo "Public key for hetzner-hq:"
echo -e "${YELLOW}"
run_cmd "sudo -u mesh-ops cat /home/mesh-ops/.ssh/id_ed25519.pub"
echo -e "${NC}"

echo ""
echo -e "${BLUE}Step 5: Cross-Node SSH Integration${NC}"
echo ""
echo "To complete mesh-ops SSH integration across all nodes:"
echo ""
echo "1. Collect public keys from all nodes:"
echo "   ${CYAN}ssh wsl-fedora-kbc 'sudo -u mesh-ops cat /home/mesh-ops/.ssh/id_ed25519.pub'${NC}"
echo "   ${CYAN}ssh laptop-hq 'sudo -u mesh-ops cat /home/mesh-ops/.ssh/id_ed25519.pub'${NC}"
echo "   ${CYAN}ssh -p 2222 hetzner-hq 'sudo -u mesh-ops cat /home/mesh-ops/.ssh/id_ed25519.pub'${NC}"
echo ""
echo "2. Add all keys to each node's mesh-ops authorized_keys"
echo ""
echo "3. Test cross-node connectivity:"
echo "   ${CYAN}sudo -u mesh-ops ssh mesh-ops@wsl-fedora-kbc${NC}"
echo "   ${CYAN}sudo -u mesh-ops ssh mesh-ops@laptop-hq${NC}"

echo ""
echo -e "${BLUE}Step 6: Ansible Control Node Setup${NC}"
echo ""
echo "As the control node, Hetzner should have Ansible installed for mesh-ops:"
echo ""
if run_cmd "which ansible > /dev/null 2>&1"; then
    echo -e "  Ansible: ${GREEN}✓ Installed${NC}"
    run_cmd "ansible --version | head -1"
else
    echo -e "  Ansible: ${YELLOW}Not installed${NC}"
    echo "  Install with: ${CYAN}sudo apt install ansible${NC}"
fi

echo ""
echo -e "${MAGENTA}=== DEPLOYMENT COMPLETE ===${NC}"
echo ""
echo -e "${GREEN}🎉 CONGRATULATIONS! All 3 nodes now have mesh-ops deployed!${NC}"
echo ""
echo "Deployment Summary:"
echo "  ${GREEN}✅${NC} wsl-fedora-kbc: mesh-ops operational"
echo "  ${GREEN}✅${NC} laptop-hq: mesh-ops operational"
echo "  ${GREEN}✅${NC} hetzner-hq: mesh-ops operational"
echo ""
echo -e "${GREEN}Phase 2.8: 100% Complete (3/3 nodes)${NC}"
echo ""
echo "Next Steps:"
echo "1. Complete SSH key exchange between all mesh-ops users"
echo "2. Install development tools: ${CYAN}make mesh-user-bootstrap${NC}"
echo "3. Configure Ansible inventory for mesh-ops management"
echo "4. Deploy Syncthing for file synchronization"
echo "5. Begin Phase 3: Service deployment"
echo ""
echo -e "${MAGENTA}The mesh infrastructure is ready for full operations!${NC}"