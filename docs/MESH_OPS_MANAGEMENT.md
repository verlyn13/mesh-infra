# Mesh-Ops User Management Guide

## Overview

The mesh-ops user is now deployed across all three nodes of the mesh infrastructure, providing a dedicated environment for infrastructure operations, development tools, and agent orchestration.

## Deployment Status: 100% Complete ✅

| Node | Status | UID/GID | SSH Access | Special Notes |
|------|--------|---------|------------|---------------|
| **wsl-fedora-kbc** | ✅ Operational | 2000/2000 | `ssh mesh-ops@wsl-fedora-kbc` | WSL2 adaptations, userspace Tailscale |
| **laptop-hq** | ✅ Operational | 2000/2000 | `ssh mesh-ops@laptop-hq` | Full Linux environment, Docker access |
| **hetzner-hq** | ✅ Operational | 2000/2000 | `ssh -p 2222 mesh-ops@91.99.101.204` | Production constraints, read-only system access |

## Access Methods

### Direct SSH Access
```bash
# WSL node (corporate environment)
ssh mesh-ops@wsl-fedora-kbc
ssh mesh-ops@100.88.131.44

# Laptop node (personal workstation)  
ssh mesh-ops@laptop-hq
ssh mesh-ops@100.84.2.8

# Hetzner node (production hub)
ssh -p 2222 mesh-ops@hetzner-hq
ssh -p 2222 mesh-ops@91.99.101.204
ssh -p 2222 mesh-ops@100.84.151.58
```

### Local User Switching
```bash
# From your personal account on each node
sudo su - mesh-ops
```

### Cross-Node Connectivity
SSH keys are generated for each mesh-ops user. Exchange keys for passwordless access:

```bash
# Get public keys from each node
ssh wsl-fedora-kbc 'sudo -u mesh-ops cat /home/mesh-ops/.ssh/id_ed25519.pub'
ssh laptop-hq 'sudo -u mesh-ops cat /home/mesh-ops/.ssh/id_ed25519.pub'  
ssh -p 2222 hetzner-hq 'sudo -u mesh-ops cat /home/mesh-ops/.ssh/id_ed25519.pub'

# Add to authorized_keys on other nodes
# (Each mesh-ops user should have all three keys in ~/.ssh/authorized_keys)
```

## Node-Specific Capabilities

### WSL Node (wsl-fedora-kbc)
```bash
# Capabilities
- WSL2-adapted environment
- Userspace Tailscale networking
- DNS fix utilities
- Windows interop configured
- Corporate network compliant

# Limitations  
- No Docker group (use rootless Podman)
- Limited system service control
- Userspace networking required

# Sudo permissions
- systemctl --user *
- apt install/update
- tailscale commands
- DNS and runtime directory fixes
```

### Laptop Node (laptop-hq)  
```bash
# Capabilities
- Full Linux environment
- Docker and Podman access
- Native systemd support
- Complete development environment

# Groups
- wheel (Fedora admin group)
- docker (container access)
- systemd-journal (log access)

# Sudo permissions
- systemctl restart/start/stop/status tailscaled
- dnf install/update
- docker/podman commands
- firewall-cmd
- systemctl --user *
```

### Hetzner Node (hetzner-hq) - Production Constraints
```bash
# Capabilities (READ-ONLY MODEL)
- Infrastructure monitoring
- User-space development
- Mesh network connectivity testing

# Restrictions (for production safety)
- NO system service control
- NO package management
- NO system configuration changes

# Sudo permissions (limited)
- docker ps (read-only)
- docker logs -n 50 * (read-only)
- journalctl -n 100 (read-only)
- tailscale status (read-only)
```

## Common Tasks

### Development Tools Installation
```bash
# Bootstrap development tools on each node
cd ~/Projects/verlyn13/mesh-infra
make mesh-user-bootstrap

# Or manually install
curl -LsSf https://astral.sh/uv/install.sh | sh     # Python
curl -fsSL https://bun.sh/install | bash            # JavaScript  
curl https://mise.run | sh                          # Version manager
```

### Service Management

#### User-Level Services (All Nodes)
```bash
# These work on all nodes (user scope)
systemctl --user start syncthing
systemctl --user enable code-server
systemctl --user status jupyter
```

#### System Services (WSL/Laptop Only)
```bash
# WSL and Laptop can control specific system services
sudo systemctl restart tailscaled
sudo systemctl status tailscaled

# Hetzner: READ-ONLY monitoring only
sudo docker ps                    # View containers
sudo journalctl -n 100            # View logs
sudo tailscale status              # Check mesh status
```

### File Synchronization
Each mesh-ops user has these directories:
```
/home/mesh-ops/
├── Projects/          # Development work
│   ├── agents/        # AI agent workspaces
│   ├── shared/        # Cross-node shared code
│   └── tools/         # Utilities and scripts
├── Scripts/           # Node-specific scripts
├── Sync/             # Syncthing sync folder (when deployed)
└── .config/          # User configurations
```

## Troubleshooting

### SSH Access Issues
```bash
# Check SSH service
sudo systemctl status sshd

# Check specific user access
sudo sshd -T | grep -i allowusers

# Test from localhost
ssh -v mesh-ops@localhost
```

### Permission Issues
```bash
# Check user existence
id mesh-ops

# Check sudo configuration  
sudo -u mesh-ops sudo -l

# Validate sudoers syntax
sudo visudo -c -f /etc/sudoers.d/50-mesh-ops*
```

### Network Connectivity
```bash
# Test mesh network as mesh-ops
ping hetzner-hq
ping laptop-hq  
ping wsl-fedora-kbc

# Check Tailscale status
tailscale status
```

## Security Model

### Development Nodes (WSL/Laptop)
- **Purpose**: Full development and testing environment
- **Trust Level**: High (user-controlled environments)
- **Permissions**: Broad sudo access for infrastructure tools

### Production Node (Hetzner)
- **Purpose**: Read-only monitoring and user-space development
- **Trust Level**: Production (critical services hosted)
- **Permissions**: Minimal, read-only system access

### Common Security Practices
- Consistent UID/GID (2000) across all nodes
- SSH key-based authentication
- User-scoped systemd services when possible
- No wildcards in sudo rules for critical services

## Next Steps (Phase 2.9)

1. **Cross-Node SSH Key Exchange**
   - Distribute all mesh-ops public keys
   - Test passwordless mesh-ops-to-mesh-ops access

2. **Development Tools Deployment**
   - Install uv, bun, mise on all nodes
   - Configure shell environments (fish/bash)
   - Set up version management

3. **Service Deployment**
   - Syncthing for file synchronization
   - Code-server for remote development
   - Jupyter for interactive computing

4. **Agent Orchestration**
   - Configure AI tools with mesh-ops API keys
   - Set up agent workspaces
   - Test cross-node agent operations

## Emergency Procedures

### If Mesh-Ops Access is Lost
```bash
# Always available: switch from personal account
sudo su - mesh-ops

# For Hetzner specifically: console access
# URL: https://console.hetzner.cloud
# Password: (stored in secure location)
```

### If SSH is Broken Again
1. **Never use wildcard sudo permissions**
2. **Use Hetzner console for emergency access**
3. **Check sudoers with visudo -c before applying**
4. **Refer to INCIDENT_REPORT_SSH_OUTAGE.md**

---

**Document Status**: Current as of 2025-09-08 21:17 UTC  
**Phase**: 2.8 Complete, Ready for Phase 2.9  
**All Nodes**: mesh-ops operational and accessible