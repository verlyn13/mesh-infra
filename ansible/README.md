# Ansible Configuration Management

This directory contains Ansible playbooks and roles for managing the mesh network infrastructure.

## 🎯 Purpose

Provide automated, consistent configuration management across all mesh nodes using Ansible with Hetzner as the control node.

## 📁 Structure

```
ansible/
├── ansible.cfg            # Ansible configuration
├── inventory/            # Node inventory
│   ├── hosts.yaml       # Static inventory
│   └── group_vars/      # Group variables
├── playbooks/           # Playbooks
│   ├── site.yaml       # Main playbook
│   └── install-tools.yaml  # Minimal useful setup
├── roles/              # Ansible roles
│   ├── common/         # Baseline configuration
│   ├── tailscale/      # Mesh network management
│   ├── security/       # Security hardening
│   └── syncthing/      # File sync (Phase 3)
└── scripts/            # Helper scripts
    ├── setup.sh        # Initial setup on Hetzner
    └── deploy.sh       # Run playbooks (wrapper)
```

## 🚀 Quick Start

### On Hetzner (Control Node)

```bash
# One-time setup (on Hetzner)
cd mesh-infra/ansible
./scripts/setup.sh

# Deploy configuration to all nodes
./scripts/deploy.sh

# Run specific playbook
ansible-playbook playbooks/site.yaml

# Test connectivity
ansible all -m ping

### From repo root using Makefile

```bash
make ansible-setup          # Run setup script on control node
make ansible-ping           # Ping all nodes via Ansible
make ansible-site           # Run main site playbook
make ansible-install-tools  # Install dev tools everywhere
```
```

## 📝 Inventory

Nodes are defined in `inventory/hosts.yaml` using Tailscale hostnames:
- `hetzner.hq` - Hub/control node
- `laptop.hq` - Fedora laptop workstation
- `wsl.hq` - WSL2 workstation (pending)

## 🔐 Security

- SSH key authentication only
- Dedicated Ansible SSH key
- ansible-vault for secrets
- No new network ports required (uses Tailscale mesh)

## 📚 Documentation

- [Setup Guide](../docs/ANSIBLE_SETUP_GUIDE.md)
- [Phase 2 Plan](../docs/PHASE2_PLAN.md)
- [Main README](../README.md)

## ⚠️ Important

This configuration is managed by the mesh-infra repository. Device-specific repositories (like fedora-top-mesh) consume but don't modify these configurations.
