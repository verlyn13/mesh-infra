
## Step 1: Initialize Your Repository Structure

Let's create a repo that merges your network infrastructure needs with agent-resistant patterns:

```bash
# Create the base repository structure
mkdir -p ~/Projects/verlyn13/mesh-infra
cd ~/Projects/verlyn13/mesh-infra
git init

# Create the grounding bundle for agents (CRITICAL for Claude Code/Windsurf)
mkdir -p docs/_grounding/{adr,sessions}
mkdir -p docs/_generated
mkdir -p infra/{policy/intent,bootstrap,backup/wg,scripts}
mkdir -p .session

# Create the core grounding files that agents MUST read first
cat > docs/_grounding/facts.yml << 'EOF'
version: 1
project: three_node_mesh_infrastructure
approach: platform_as_code
last_updated: 2025-09-05
owner: verlyn13

# Immutable System Facts
nodes:
  hetzner:
    hostname: docker-cx32-prod
    public_ipv4: 91.99.101.204
    ssh_port: 2222
    role: [hub, headquarters, server]
    always_on: true
  laptop:
    hostname: fedora-top
    role: [workstation, roaming]
    roaming: true
  wsl:
    hostname: fedora-wsl
    windows_host: KBC-JJOHNSON47
    role: [workstation, windows_dev_env]
    constraints: [no_windows_admin, wsl2]

network:
  internal_domain: hq
  mesh_subnet: 10.0.0.0/24
  node_ips:
    hetzner: 10.0.0.1
    laptop: 10.0.0.2
    wsl: 10.0.0.3

security:
  ssh_user: verlyn13
  token_expiry: 24h
  admin_ports: [22, 443, 8080]
  emergency_ssh: 2222

tools:
  vpn: tailscale  # or wireguard
  config_mgmt: ansible  # future
  secrets: gopass
  orchestration: systemd
EOF

# Create the module map for ownership
cat > docs/_grounding/module_map.json << 'EOF'
{
  "modules": {
    "infra/policy": {
      "owner": "verlyn13",
      "description": "Network policies and intent",
      "protected": true
    },
    "infra/bootstrap": {
      "owner": "verlyn13",
      "description": "Node joining and initialization"
    },
    "infra/scripts": {
      "owner": "verlyn13",
      "description": "Automation scripts"
    },
    "docs/_grounding": {
      "owner": "verlyn13",
      "description": "Source of truth - DO NOT MODIFY",
      "protected": true
    }
  }
}
EOF

# Create the roadmap
cat > docs/_grounding/roadmap.md << 'EOF'
# Infrastructure Roadmap

## Current Phase: Day 1 - Foundation
- [x] Repository structure
- [ ] Tailscale mesh establishment
- [ ] Emergency access hatches
- [ ] Node join protocol
- [ ] Security baseline

## Next Phases
- Phase 2: Configuration Management
- Phase 3: File Synchronization
- Phase 4: Observability
- Phase 5: Agent Orchestration
EOF
```

## Step 2: Policy Abstraction Layer (Vendor-Neutral)

```bash
# Create the vendor-neutral network policy
cat > infra/policy/intent/network.yaml << 'EOF'
# THIS IS YOUR SOURCE OF TRUTH - VENDOR NEUTRAL
# Agents: DO NOT modify this directly, use the generator

version: 1
metadata:
  description: "Vendor-neutral network intent"
  last_updated: 2025-09-05

nodes:
  hetzner:
    fqdn: hetzner.hq
    internal_ip: 10.0.0.1/24
    roles: [hub, server]
    always_on: true
    services:
      - ssh
      - infisical
    
  laptop:
    fqdn: laptop.hq
    internal_ip: 10.0.0.2/24
    roles: [workstation]
    roaming: true
    
  wsl:
    fqdn: wsl.hq
    internal_ip: 10.0.0.3/24
    roles: [workstation]
    constraints: [no_host_admin, wsl2]

access_policy:
  - name: admin_full_access
    from: admin
    to: "*"
    ports: "*"
    
  - name: workstation_to_server
    from: role:workstation
    to: role:server
    ports: [22, 443, 8080]
    
  - name: emergency_ssh
    from: "*"
    to: hetzner
    ports: [2222]
    rate_limit: 1/minute

security_invariants:
  - admin_ports_never_public
  - tokens_expire_24h
  - ssh_key_only_auth
  - default_deny_inbound
EOF

# Create the policy generator
cat > infra/policy/intent/generate.sh << 'EOF'
#!/bin/bash
# Transforms vendor-neutral policy to implementation-specific configs

set -euo pipefail

POLICY_FILE="network.yaml"
OUTPUT_DIR="../generated"

mkdir -p "$OUTPUT_DIR"

# For now, we'll generate Tailscale ACLs
# TODO: Add WireGuard config generation as fallback

echo "Generating Tailscale ACL from $POLICY_FILE..."

cat > "$OUTPUT_DIR/tailscale-acl.json" << 'EOJSON'
{
  "tagOwners": {
    "tag:server": ["verlyn13@github"],
    "tag:workstation": ["verlyn13@github"]
  },
  "acls": [
    {
      "action": "accept",
      "src": ["verlyn13@github"],
      "dst": ["*:*"]
    },
    {
      "action": "accept",
      "src": ["tag:workstation"],
      "dst": ["tag:server:22,443,8080"]
    }
  ],
  "ssh": [
    {
      "action": "accept",
      "src": ["verlyn13@github"],
      "dst": ["tag:server"],
      "users": ["verlyn13", "root"]
    }
  ]
}
EOJSON

echo "✓ Generated Tailscale ACL"
echo "Files created in $OUTPUT_DIR/"
EOF

chmod +x infra/policy/intent/generate.sh
```

## Step 3: Session Management for Agents

```bash
# Create the session template for agents
cat > docs/_grounding/session_template.md << 'EOF'
# Agent Session Template

## Before Starting
1. Run: `make ground-pull` to sync latest state
2. Read: docs/_grounding/facts.yml
3. Check: git status and current branch

## Session Contract
```yaml
session_id: [auto-generated]
started_at: [timestamp]
agent: [claude-code|windsurf|codex]
commit: [git-hash]
scope:
  include: []  # paths agent can modify
  exclude: [docs/_grounding/*, infra/policy/intent/*]  # never touch
goals:
  - [specific deliverable]
constraints:
  - Do not modify grounding files
  - All changes must have tests
  - Update docs/_generated/snapshot.json before commit
```

## Required Checks Before PR
- [ ] Session file created in .session/
- [ ] facts.yml unchanged
- [ ] Tests added/updated
- [ ] Snapshot regenerated
- [ ] No scope violations
EOF

# Create helper scripts for agents
cat > scripts/ground.py << 'EOF'
#!/usr/bin/env python3
"""
Ground CLI - Agent interface to repository state
Usage:
  ground pull    - Read current state
  ground plan    - Create session plan
  ground commit  - Validate and prepare commit
"""

import json
import yaml
import sys
import subprocess
from pathlib import Path
from datetime import datetime

def pull():
    """Load and display current repository state"""
    facts = Path("docs/_grounding/facts.yml")
    if facts.exists():
        with open(facts) as f:
            data = yaml.safe_load(f)
        print(json.dumps(data, indent=2))
    
    # Show git status
    result = subprocess.run(["git", "status", "--short"], capture_output=True, text=True)
    if result.stdout:
        print("\nUncommitted changes:")
        print(result.stdout)

def plan():
    """Create a new session plan"""
    session_id = datetime.now().strftime("%Y%m%d-%H%M%S")
    commit = subprocess.run(["git", "rev-parse", "HEAD"], capture_output=True, text=True).stdout.strip()
    
    session = {
        "session_id": session_id,
        "started_at": datetime.now().isoformat(),
        "agent": "unknown",  # Agent should specify
        "commit": commit[:8],
        "scope": {
            "include": [],
            "exclude": ["docs/_grounding/*", "infra/policy/intent/*"]
        },
        "goals": [],
        "constraints": [
            "Do not modify grounding files",
            "All changes must have tests",
            "Update snapshot before commit"
        ]
    }
    
    session_file = Path(f".session/session-{session_id}.yaml")
    session_file.parent.mkdir(exist_ok=True)
    
    with open(session_file, 'w') as f:
        yaml.dump(session, f)
    
    print(f"Created session: {session_file}")
    return str(session_file)

def commit():
    """Validate changes before commit"""
    # Check for grounding file modifications
    result = subprocess.run(["git", "diff", "--name-only", "docs/_grounding/"], 
                          capture_output=True, text=True)
    if result.stdout:
        print("ERROR: Grounding files modified!")
        print(result.stdout)
        sys.exit(1)
    
    # Regenerate snapshot
    print("Regenerating snapshot...")
    subprocess.run(["python3", "scripts/repo_probe.py"])
    
    print("✓ Ready to commit")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    
    command = sys.argv[1]
    if command == "pull":
        pull()
    elif command == "plan":
        plan()
    elif command == "commit":
        commit()
    else:
        print(f"Unknown command: {command}")
        sys.exit(1)
EOF

chmod +x scripts/ground.py
```

## Step 4: Repository Probe and Snapshot

```bash
cat > scripts/repo_probe.py << 'EOF'
#!/usr/bin/env python3
"""Generate repository snapshot for state tracking"""

import json
import subprocess
from pathlib import Path
from datetime import datetime

def get_git_info():
    """Get current git state"""
    return {
        "head": subprocess.run(["git", "rev-parse", "HEAD"], 
                              capture_output=True, text=True).stdout.strip()[:8],
        "branch": subprocess.run(["git", "branch", "--show-current"], 
                                capture_output=True, text=True).stdout.strip(),
        "dirty": bool(subprocess.run(["git", "diff", "--quiet"], 
                                    capture_output=True).returncode)
    }

def scan_infrastructure():
    """Scan infrastructure files"""
    infra_path = Path("infra")
    return {
        "scripts": len(list(infra_path.glob("scripts/*.sh"))),
        "policies": len(list(infra_path.glob("policy/intent/*.yaml"))),
        "backups": infra_path.joinpath("backup/wg").exists()
    }

def generate_snapshot():
    """Generate complete snapshot"""
    snapshot = {
        "timestamp": datetime.now().isoformat(),
        "git": get_git_info(),
        "infrastructure": scan_infrastructure(),
        "nodes": {
            "configured": ["hetzner", "laptop", "wsl"],
            "mesh_network": "10.0.0.0/24"
        }
    }
    
    output_path = Path("docs/_generated/snapshot.json")
    output_path.parent.mkdir(exist_ok=True, parents=True)
    
    with open(output_path, 'w') as f:
        json.dump(snapshot, f, indent=2)
    
    print(f"Snapshot saved to {output_path}")
    return snapshot

if __name__ == "__main__":
    generate_snapshot()
EOF

chmod +x scripts/repo_probe.py
```

## Step 5: Makefile for Common Operations

```bash
cat > Makefile << 'EOF'
.PHONY: help ground-pull ground-plan probe init-day1 escape-hatch test

help:
	@echo "Mesh Infrastructure Management"
	@echo "  make init-day1    - Initialize Day 1 infrastructure"
	@echo "  make ground-pull  - Sync repository state (for agents)"
	@echo "  make ground-plan  - Create new session plan"
	@echo "  make probe        - Generate repository snapshot"
	@echo "  make escape-hatch - Show emergency access methods"

ground-pull:
	@python3 scripts/ground.py pull

ground-plan:
	@python3 scripts/ground.py plan

probe:
	@python3 scripts/repo_probe.py

init-day1:
	@echo "Starting Day 1 initialization..."
	@bash infra/scripts/init-day1.sh

escape-hatch:
	@echo "=== EMERGENCY ACCESS ==="
	@echo "1. Direct SSH: ssh verlyn13@91.99.101.204 -p 2222"
	@echo "2. WireGuard: wg-quick up infra/backup/wg/emergency.conf"
	@echo "3. Console: Hetzner web console"

test:
	@echo "Testing mesh connectivity..."
	@bash infra/scripts/test-mesh.sh
EOF
```

## Step 6: Day 1 Initialization Script

```bash
cat > infra/scripts/init-day1.sh << 'EOF'
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
EOF

chmod +x infra/scripts/init-day1.sh
```

## Step 7: Emergency Access Documentation

```bash
cat > infra/ESCAPE_HATCHES.md << 'EOF'
# Emergency Access Procedures

## When Mesh VPN is Down

### 1. Direct SSH to Hetzner (Primary)
```bash
ssh verlyn13@91.99.101.204 -p 2222
```

### 2. WireGuard Fallback (Secondary)
```bash
# If Tailscale fails, use pre-configured WireGuard
sudo wg-quick up /path/to/infra/backup/wg/emergency.conf
```

### 3. Hetzner Console (Last Resort)
- Login to Hetzner Cloud Console
- Use VNC console access
- Reset networking if needed

## Recovery Procedures

### Restart Tailscale
```bash
# On Hetzner
sudo systemctl restart tailscaled
sudo tailscale up --advertise-exit-node --advertise-routes=172.20.0.0/16

# On clients
sudo systemctl restart tailscaled
sudo tailscale up --accept-routes
```

### Check Firewall Rules
```bash
# Verify emergency SSH is accessible
sudo ufw status
sudo iptables -L -n | grep 2222
```

### Network Diagnostics
```bash
# Test connectivity
tailscale ping hetzner-hq
tailscale netcheck

# Check routes
ip route show table all | grep tailscale
```

## Important IPs
- Hetzner Public: 91.99.101.204
- Mesh Network: 10.0.0.0/24
  - Hetzner: 10.0.0.1
  - Laptop: 10.0.0.2
  - WSL: 10.0.0.3
EOF
```

## Step 8: Git Configuration

```bash
# Create .gitignore
cat > .gitignore << 'EOF'
# Secrets and keys
*.key
*.pem
*.crt
infra/backup/wg/*.key
infra/backup/wg/*.conf

# Session files (agent-specific)
.session/session-*.yaml

# Generated files
docs/_generated/pr_manifest.json

# Temporary files
*.tmp
*.swp
.DS_Store

# Python
__pycache__/
*.pyc
.venv/

# Ansible
*.retry

# Terraform (future)
*.tfstate
*.tfstate.backup
.terraform/
EOF

# Create CODEOWNERS for protection
cat > CODEOWNERS << 'EOF'
# Protected paths - only owner can modify
/docs/_grounding/facts.yml         @verlyn13
/infra/policy/intent/              @verlyn13
/docs/_grounding/module_map.json   @verlyn13
EOF

# Initial commit
git add .
git commit -m "Initial commit: Day 1 mesh infrastructure foundation

- Repository structure with grounding bundle for AI agents
- Vendor-neutral network policies
- Session management for Claude Code/Windsurf
- Emergency access procedures
- Probe and snapshot tooling"
```

## Step 9: Quick Start Commands

Now you can run:

```bash
# 1. Initialize your first node (start with Hetzner)
make init-day1

# 2. Generate a session plan (for agent work)
make ground-plan

# 3. Check repository state
make probe

# 4. View emergency access options
make escape-hatch
```

## For Your AI Assistants (Claude Code, Windsurf)

Create this instruction file for them:

```bash
cat > .claude-instructions << 'EOF'
# Instructions for AI Assistants

## CRITICAL: Before ANY work
1. Run: `make ground-pull`
2. Read: `docs/_grounding/facts.yml`
3. Create session: `make ground-plan`

## NEVER MODIFY
- docs/_grounding/facts.yml
- infra/policy/intent/*.yaml
- CODEOWNERS file

## ALWAYS DO
- Update tests when changing code
- Run `make probe` before commits
- Stay within declared session scope
- Check git branch before starting

## Project Context
This is a three-node mesh network infrastructure:
- Hetzner (hub): Always-on server
- Laptop: Roaming workstation
- WSL: Windows-constrained workstation

Current phase: Day 1 - Establishing basic connectivity
EOF
```

## Next Steps

1. **Start with Hetzner node**: SSH in and run `make init-day1`
2. **Verify Tailscale is running**: `tailscale status`  
3. **Join your laptop**: Run the same init on your laptop
4. **Join WSL last**: May need special handling for WSL networking
5. **Test connectivity**: From any node, try `ping 10.0.0.1`

This structure gives you:
- **Agent-resistant design**: Grounding files they can't corrupt
- **Clear boundaries**: What can/cannot be modified
- **Session tracking**: Know what each agent session did
- **Emergency access**: Multiple fallback methods
- **Progressive implementation**: Start simple, add complexity later

Ready to start with your Hetzner node?
