# Phase 3 Deployment Guide: Syncthing Implementation
**Complete 3-Node File Synchronization**

*Status: Ready for Deployment*  
*Updated: 2025-09-07*

## 🎯 Deployment Overview

This guide provides step-by-step instructions for deploying Syncthing file synchronization across the complete 3-node mesh network.

## 📋 Pre-Deployment Checklist

### Infrastructure Requirements
- [x] **3-Node Mesh**: All nodes operational and connected via Tailscale
  - hetzner-hq: 100.84.151.58 (Hub/Control Node)
  - laptop-hq: 100.84.2.8 (Mobile Workstation)
  - wsl-fedora-kbc: 100.88.131.44 (Work Environment)
- [x] **Ansible Control**: Operational on Hetzner with SSH access to all nodes
- [x] **Network Connectivity**: Tailscale mesh providing encrypted tunnels
- [x] **User Permissions**: `verlyn13` user with sudo access on all nodes

### Role Implementation Status
- [x] **Ansible Role Structure**: Complete syncthing role in `ansible/roles/syncthing/`
- [x] **Host Variables**: Node-specific configurations in `inventory/host_vars/`
- [x] **Deployment Playbook**: `playbooks/syncthing.yaml` ready for execution
- [x] **Makefile Integration**: `make syncthing-deploy` and `make syncthing-status` commands

## 🚀 Deployment Sequence

### Phase 3.1: Syntax Validation and Pre-Flight

```bash
# Run from Hetzner control node
cd /opt/mesh-infra/ansible

# 1. Validate playbook syntax
ansible-playbook --syntax-check playbooks/syncthing.yaml

# 2. Dry run to see what would be changed
ansible-playbook --check playbooks/syncthing.yaml

# 3. Verify connectivity to all nodes
ansible all -m ping
```

### Phase 3.2: Stable Nodes Deployment (Hetzner + Laptop)

```bash
# Deploy to stable nodes first
ansible-playbook -l hetzner.hq,laptop.hq playbooks/syncthing.yaml

# Verify service status
ansible hetzner.hq,laptop.hq -m shell -a 'systemctl status syncthing@verlyn13'

# Check basic connectivity
ansible hetzner.hq,laptop.hq -m shell -a 'curl -s http://127.0.0.1:8384/rest/system/status | jq .systemState'
```

### Phase 3.3: WSL2 Integration

```bash
# Deploy to WSL2 node (may need special handling)
ansible-playbook -l wsl.hq playbooks/syncthing.yaml

# Verify WSL2-specific service (user mode)
ansible wsl.hq -m shell -a 'systemctl --user status syncthing'

# Alternative: Use custom startup script if systemd issues
ansible wsl.hq -m shell -a '/home/verlyn13/bin/start-syncthing.sh status'
```

### Phase 3.4: Full Network Validation

```bash
# Deploy to all nodes (complete rollout)
ansible-playbook playbooks/syncthing.yaml

# Check service status across all nodes
make syncthing-status

# Verify API connectivity
ansible all -m shell -a 'curl -s -f http://127.0.0.1:8384/rest/system/ping'
```

## 📊 Sync Folder Architecture

### Folder Configuration by Node

#### Hetzner Hub (Storage/Backup)
```yaml
development/     # 3-way bidirectional sync
documents/       # Receive-only (backup from laptop/wsl)
config/          # Selective configuration sync
work/            # WSL ↔ Hetzner only
```

#### Laptop (Mobile Workstation)
```yaml
development/     # Active development projects
documents/       # Send-only (backup to hetzner)
config/          # Dotfiles and settings
# (no work/ folder - maintains separation)
```

#### WSL2 (Work Environment)
```yaml
development/     # Shared tools and utilities
work/            # Work projects (WSL ↔ Hetzner only)
config/          # Work-appropriate configurations
# (no documents/ folder - maintains separation)
```

## 🔧 Post-Deployment Configuration

### Device Connection Setup

1. **Access Web UIs** (from respective nodes):
   ```bash
   # Hetzner: External access allowed
   http://100.84.151.58:8384
   
   # Laptop: Local access only
   http://127.0.0.1:8384
   
   # WSL2: Local access only  
   http://127.0.0.1:8384
   ```

2. **Device ID Exchange**: Automatic via Ansible configuration
3. **Folder Sharing**: Pre-configured based on host_vars

### Initial Sync Testing

1. **Create Test Files**:
   ```bash
   # On laptop
   echo "Test from laptop" > ~/sync/development/laptop-test.txt
   
   # On WSL2
   echo "Test from WSL2" > ~/sync/work/wsl-test.txt
   
   # On Hetzner
   echo "Test from Hetzner" > ~/sync/development/hetzner-test.txt
   ```

2. **Verify Synchronization**:
   ```bash
   # Check files appear on appropriate nodes
   ansible all -m shell -a 'ls -la /home/verlyn13/sync/development/'
   ansible hetzner.hq,wsl.hq -m shell -a 'ls -la /home/verlyn13/sync/work/'
   ```

## 🔍 Monitoring and Health Checks

### Service Health Commands
```bash
# Service status
make syncthing-status

# API health across all nodes
ansible all -m uri -a 'url=http://127.0.0.1:8384/rest/system/status method=GET'

# Folder sync status
ansible all -m shell -a 'curl -s http://127.0.0.1:8384/rest/db/status | jq'

# Network connectivity
ansible all -m shell -a 'syncthing cli show system | head -10'
```

### Log Monitoring
```bash
# System service logs
ansible all -m shell -a 'journalctl -u syncthing@verlyn13 --since "10 minutes ago"'

# User service logs (WSL2)
ansible wsl.hq -m shell -a 'journalctl --user -u syncthing --since "10 minutes ago"'
```

## ⚠️ Troubleshooting Guide

### Common Issues and Solutions

#### Issue: Service Won't Start
```bash
# Check service status and logs
systemctl status syncthing@verlyn13
journalctl -u syncthing@verlyn13 -f

# Verify configuration
syncthing --config=/home/verlyn13/.config/syncthing --verify
```

#### Issue: WSL2 Service Problems
```bash
# Try user service mode
systemctl --user start syncthing
systemctl --user status syncthing

# Fallback to manual startup script
/home/verlyn13/bin/start-syncthing.sh start
```

#### Issue: Devices Not Connecting
```bash
# Check device IDs in config
grep -A 5 "<device id=" /home/verlyn13/.config/syncthing/config.xml

# Verify network connectivity
tailscale ping <other-node-ip>
nc -zv <other-node-ip> 22000
```

#### Issue: Folders Not Syncing
```bash
# Check folder configuration
curl -s http://127.0.0.1:8384/rest/db/status | jq '.[].globalBytes'

# Look for errors
curl -s http://127.0.0.1:8384/rest/system/log | jq '.messages[]'
```

## 🔄 Rollback Procedures

### If Deployment Fails
```bash
# Stop all services
ansible all -m systemd -a 'name=syncthing@verlyn13 state=stopped'

# Remove configurations
ansible all -m file -a 'path=/home/verlyn13/.config/syncthing state=absent'

# Uninstall packages
ansible all -m package -a 'name=syncthing state=absent'

# Restore from git
git checkout HEAD~1
```

### If Sync Issues Occur
```bash
# Pause problematic folders
curl -X POST http://127.0.0.1:8384/rest/system/pause

# Reset folder database
curl -X POST http://127.0.0.1:8384/rest/db/reset?folder=<folder-id>

# Resume after resolution
curl -X POST http://127.0.0.1:8384/rest/system/resume
```

## 📈 Performance Optimization

### Post-Deployment Tuning
1. **Monitor Initial Sync**: Large transfers will take time
2. **Adjust Scan Intervals**: Based on usage patterns
3. **Optimize Versioning**: Balance history vs. storage
4. **Network Tuning**: Bandwidth limits if needed

### Performance Metrics
```bash
# Sync transfer rates
curl -s http://127.0.0.1:8384/rest/system/status | jq '.connectionServiceStatus'

# Folder statistics
curl -s http://127.0.0.1:8384/rest/db/status | jq '.[].localBytes'

# System resource usage
ansible all -m shell -a 'ps aux | grep syncthing'
```

## 🎉 Success Criteria

### Deployment Success Indicators
- [ ] Syncthing service running on all 3 nodes
- [ ] Web UI accessible on each node
- [ ] All devices visible and connected
- [ ] Folders configured per design
- [ ] Test file sync working bidirectionally
- [ ] No critical errors in logs

### Operational Success Indicators  
- [ ] File changes sync within 2 minutes
- [ ] Conflict resolution working correctly
- [ ] Services restart automatically after reboot
- [ ] Web monitoring functional
- [ ] Selective sync rules working (work/personal boundaries)

## 📝 Next Steps After Deployment

1. **Production Usage**: Start with small files, gradually increase
2. **Backup Validation**: Verify backup copies are complete
3. **Performance Monitoring**: Watch for sync delays or conflicts
4. **Documentation Updates**: Record any deployment-specific findings
5. **Phase 4 Planning**: Prepare for observability layer

---

**Phase 3 deployment is ready to execute! Run from Hetzner control node.**