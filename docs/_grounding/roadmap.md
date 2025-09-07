# Infrastructure Roadmap

## ✅ Day 1 - Foundation (Partial Completion: 2025-09-06)
- [x] Repository structure
- [x] Tailscale mesh establishment (Hub and laptop deployed)
- [x] Emergency access hatches (Documented and tested)
- [x] Node join protocol (Scripts ready)
- [x] Security baseline (WireGuard encryption active)
- [ ] All three nodes connected (2/3 complete - 66%)

## 🚧 Phase 2: Configuration Management (Starting: 2025-09-06)
- [ ] Install Ansible on Hetzner control node
- [ ] Create ansible/ directory structure in mesh-infra
- [ ] Set up SSH keys for Ansible automation
- [ ] Create inventory using Tailscale hostnames
- [ ] Develop core roles:
  - [ ] common - baseline packages and config
  - [ ] tailscale - mesh network management
  - [ ] security - SSH hardening, firewall
- [ ] Implement GitOps workflow
- [ ] Test deployment across all nodes
- [ ] Document playbook usage

## 📋 Future Phases
### Phase 3: File Synchronization
- [ ] Deploy Syncthing via Ansible role
- [ ] Configure selective sync rules
- [ ] Set up backup strategies
- [ ] Create shared directories

### Phase 4: Observability
- [ ] Prometheus metrics collection
- [ ] Loki log aggregation
- [ ] Grafana dashboards
- [ ] Alert rules

### Phase 5: Agent Orchestration
- [ ] Service discovery
- [ ] Job scheduling
- [ ] Resource allocation
- [ ] AI agent coordination