# Phase 2: Configuration Management Implementation Plan

**Start Date**: September 6, 2025  
**Target Completion**: September 8, 2025  
**Tool**: Ansible  
**Control Node**: Hetzner (always-on hub)

## 🎯 Phase 2 Objectives

1. **Establish Ansible control plane** on Hetzner
2. **Create inventory** using Tailscale as source of truth
3. **Define baseline roles** for all nodes
4. **Implement GitOps workflow** for configuration
5. **Prepare for Phase 3** (file synchronization)

## 📋 Implementation Tasks

### Day 1: Foundation (Today)
- [ ] Create ansible/ directory structure in mesh-infra
- [ ] Document Ansible architecture decision (ADR)
- [ ] Update roadmap with specific milestones
- [ ] Create placeholder files for structure

### Day 2: Hetzner Setup (Tomorrow)
- [ ] Install Ansible on Hetzner
- [ ] Configure SSH keys for Ansible
- [ ] Create inventory files
- [ ] Test connectivity to laptop node
- [ ] Create first playbook (ping test)

### Day 3: Role Development
- [ ] Create common role (baseline packages)
- [ ] Create tailscale role (ensure mesh stable)
- [ ] Create security role (SSH, firewall)
- [ ] Test roles on all connected nodes

### Day 4: GitOps Integration
- [ ] Set up ansible-pull configuration
- [ ] Create sync scripts
- [ ] Configure automated runs
- [ ] Document usage patterns

## 🏗️ Architecture Decisions

### Decision 1: Ansible Location
**Choice**: Store in mesh-infra repository under `/ansible/`
**Rationale**: 
- Centralized configuration management
- Single source of truth
- Git-backed version control
- Aligns with "mesh-infra as HQ" principle

### Decision 2: Inventory Strategy
**Choice**: Hybrid - static YAML with Tailscale dynamic fallback
**Rationale**:
- Static for predictable base config
- Dynamic for node availability
- Tailscale as authoritative network source

### Decision 3: Control Node
**Choice**: Hetzner as primary controller
**Rationale**:
- Always-on availability
- Central authority model
- Can push to all nodes
- Backup: ansible-pull from nodes

### Decision 4: Secret Management
**Choice**: ansible-vault for now, Infisical integration later
**Rationale**:
- Start simple with built-in tools
- Infisical already on Hetzner for future integration
- Gradual complexity increase

## 📁 Directory Structure

```
mesh-infra/
└── ansible/                    # Phase 2 Addition
    ├── ansible.cfg            # Ansible configuration
    ├── inventory/             # Node inventory
    │   ├── hosts.yaml        # Static inventory
    │   └── group_vars/       # Group variables
    │       ├── all.yaml
    │       ├── headquarters.yaml
    │       └── workstations.yaml
    ├── playbooks/             # Playbooks
    │   ├── site.yaml        # Main playbook
    │   ├── bootstrap.yaml   # New node setup
    │   └── update.yaml      # System updates
    ├── roles/                 # Ansible roles
    │   ├── common/          # Baseline config
    │   ├── tailscale/       # Mesh network
    │   ├── security/        # Security hardening
    │   └── syncthing/       # (Phase 3 prep)
    └── scripts/               # Helper scripts
        ├── setup.sh         # Initial setup
        └── deploy.sh        # Run playbooks
```

## 🔒 Security Considerations

1. **SSH Keys**: Dedicated ansible key (ed25519)
2. **Vault**: Encrypt sensitive variables
3. **Sudo**: NOPASSWD for ansible user on nodes
4. **Firewall**: No new ports, use existing Tailscale mesh
5. **Audit**: All changes through Git commits

## 📊 Success Criteria

### Phase 2 Complete When:
- [ ] Ansible installed and configured on Hetzner
- [ ] All online nodes in inventory
- [ ] Common role applied successfully
- [ ] Can deploy changes with single command
- [ ] Documentation updated
- [ ] GitOps workflow tested

### Validation Tests:
```bash
# From Hetzner
cd /opt/mesh-infra/ansible
ansible all -m ping                    # All nodes respond
ansible-playbook playbooks/site.yaml   # Runs without errors
./scripts/deploy.sh                    # Automated deployment works
```

## 🚀 Quick Start Commands

Once structure is in place:

```bash
# On Hetzner
cd /opt/mesh-infra
git pull
cd ansible
./scripts/setup.sh          # One-time setup
./scripts/deploy.sh          # Deploy configuration
```

## 📝 Notes

- Keep it simple initially - complexity can be added
- Focus on repeatability over features
- Document everything in code comments
- Test on laptop before WSL
- Prepare syncthing role structure for Phase 3

## 🔗 Related Documents

- [ANSIBLE_SETUP_GUIDE.md](ANSIBLE_SETUP_GUIDE.md) - Detailed setup instructions
- [file-organization.md](../docs/_grounding/file-organization.md) - Directory policies
- [roadmap.md](../docs/_grounding/roadmap.md) - Overall project phases

## ⚠️ Constraints

Per our policies:
- Ansible config stays in mesh-infra repo (not device repos)
- No modifications to protected paths
- All changes tracked in Git
- Test before production deployment
- Document architecture decisions

---

**Status**: Ready to implement  
**Next Action**: Create ansible/ directory structure in mesh-infra