# Phase 3 Implementation: File Synchronization with Syncthing
**Complete Workflow and Deployment Guide**

*Status: Ready for Implementation*  
*Updated: 2025-09-07*

## 🎯 Overview

Phase 3 implements secure, selective file synchronization across the complete 3-node mesh using Syncthing, enabling seamless data access and collaborative workflows.

## 📋 Implementation Phases

### Phase 3.1: Infrastructure Preparation ⏳
**Goal**: Create Ansible automation for Syncthing deployment  
**Duration**: 2-3 hours  
**Deliverables**:
- Complete Syncthing Ansible role
- Node-specific configurations  
- Service management automation

### Phase 3.2: Initial 2-Node Deployment ⏳
**Goal**: Deploy and test Syncthing between stable nodes  
**Duration**: 1-2 hours  
**Deliverables**:
- Syncthing running on Hetzner + Laptop
- Basic bidirectional sync working
- Monitoring and health checks

### Phase 3.3: WSL2 Integration ⏳
**Goal**: Add WSL2 node to complete 3-node sync  
**Duration**: 1-2 hours  
**Deliverables**:
- WSL2-specific Syncthing configuration
- 3-way synchronization active
- Conflict resolution testing

### Phase 3.4: Production Configuration ⏳
**Goal**: Implement selective sync rules and optimization  
**Duration**: 2-3 hours  
**Deliverables**:
- Work/personal content boundaries
- Performance optimization
- Complete documentation

## 🏗️ Technical Architecture

### Syncthing Topology
```
        ┌─────────────────┐
        │   hetzner-hq    │
        │ 100.84.151.58   │
        │  (Sync Hub)     │
        └─────────┬───────┘
                  │
          ┌───────┴───────┐
          │               │
    ┌───────────┐   ┌─────────────┐
    │ laptop-hq │   │wsl-fedora-  │
    │100.84.2.8 │   │kbc          │
    │(Mobile)   │   │100.88.131.44│
    └───────────┘   └─────────────┘
```

### Sync Folder Strategy
1. **Development**: 3-way bidirectional sync
2. **Documents**: Laptop/WSL → Hetzner backup
3. **Config Files**: Selective per-node sync
4. **Work Content**: WSL ↔ Hetzner (bypass laptop)

## 📁 Directory Structure

### Ansible Role Structure
```
ansible/roles/syncthing/
├── tasks/
│   ├── main.yaml              # Primary installation tasks
│   ├── install.yaml           # Package installation
│   ├── configure.yaml         # Service configuration
│   ├── folders.yaml           # Folder setup
│   └── firewall.yaml          # Port management
├── templates/
│   ├── config.xml.j2          # Main Syncthing config
│   ├── syncthing.service.j2   # systemd service (if needed)
│   └── folders/               # Per-folder configurations
├── handlers/
│   └── main.yaml              # Service restart handlers
├── defaults/
│   └── main.yaml              # Default variables
├── vars/
│   └── main.yaml              # Role variables
└── files/
    └── syncthing-setup.sh     # Custom setup scripts
```

### Sync Folder Layout
```
/home/verlyn13/sync/
├── development/               # Code projects (3-way sync)
│   ├── active-projects/      
│   └── shared-tools/         
├── documents/                 # Personal docs (→ hetzner backup)
│   ├── personal/             
│   └── reference/            
├── config/                    # Dotfiles (selective sync)
│   ├── shell/                
│   ├── editors/              
│   └── tools/                
└── work/                      # WSL ↔ Hetzner only
    ├── projects/             
    └── resources/            
```

## 🔧 Implementation Steps

### Step 1: Create Syncthing Ansible Role

#### 1.1 Role Directory Structure
```bash
mkdir -p ansible/roles/syncthing/{tasks,templates,handlers,defaults,vars,files}
```

#### 1.2 Main Tasks (`tasks/main.yaml`)
- Package installation (OS-specific)
- User configuration
- Service setup and enablement
- Firewall configuration
- Folder creation and permissions

#### 1.3 Configuration Template (`templates/config.xml.j2`)
- Device definitions for all nodes
- Folder configurations with selective sync
- Security settings and API keys
- WSL2-specific adaptations

#### 1.4 Service Management
- systemd service configuration
- Auto-start on boot
- Health check integration
- Log management

### Step 2: Node-Specific Configurations

#### Hetzner (Hub Node)
- **Role**: Central sync hub and backup storage
- **Folders**: All shared folders with highest retention
- **Storage**: Large disk allocation for backups
- **Services**: Web UI accessible (secured)

#### Laptop (Mobile Node)
- **Role**: Primary development workstation
- **Folders**: Active development + personal documents
- **Storage**: Selective sync to manage space
- **Services**: Auto-sync on network availability

#### WSL2 (Work Node)
- **Role**: Work environment with corporate constraints
- **Folders**: Work projects + shared development tools
- **Storage**: Limited space, selective sync
- **Services**: Manual startup if systemd limitations

### Step 3: Deployment Automation

#### 3.1 Ansible Playbook Integration
```yaml
# playbooks/syncthing.yaml
- hosts: all
  become: yes
  roles:
    - syncthing
  vars:
    syncthing_device_id: "{{ inventory_hostname }}"
    syncthing_folders: "{{ host_sync_folders }}"
```

#### 3.2 Host-Specific Variables
```yaml
# inventory/host_vars/hetzner.hq.yaml
host_sync_folders:
  - name: "development"
    type: "bidirectional"
    peers: ["laptop.hq", "wsl.hq"]
  - name: "backup-documents"
    type: "receive-only"
    peers: ["laptop.hq", "wsl.hq"]
```

#### 3.3 Makefile Integration
```makefile
# Add to existing Makefile
syncthing-deploy:
	@cd ansible && ansible-playbook playbooks/syncthing.yaml

syncthing-status:
	@cd ansible && ansible all -m shell -a 'systemctl status syncthing@verlyn13'
```

### Step 4: Security Implementation

#### 4.1 Device Authentication
- Generate unique device IDs for each node
- Implement certificate-based authentication
- Auto-accept only known devices

#### 4.2 Folder Permissions
- Granular read/write access per folder
- Work/personal content separation
- Version control integration

#### 4.3 Network Security
- All traffic via encrypted Tailscale mesh
- No external port exposure
- Firewall rules for Syncthing ports (22000, 21027)

## 🚀 Deployment Workflow

### Phase 3.1: Infrastructure Setup
```bash
# 1. Create Ansible role
make ground-plan  # Update session plan
cd ansible/roles/syncthing

# 2. Implement role components
# (Detailed implementation in following steps)

# 3. Test role syntax
ansible-playbook --syntax-check playbooks/syncthing.yaml
```

### Phase 3.2: Two-Node Deployment
```bash
# 1. Deploy to stable nodes first
ansible-playbook -l hetzner.hq,laptop.hq playbooks/syncthing.yaml

# 2. Verify 2-node sync
ansible hetzner.hq,laptop.hq -m shell -a 'systemctl status syncthing@verlyn13'

# 3. Test basic file sync
# Create test files and verify synchronization
```

### Phase 3.3: WSL2 Integration
```bash
# 1. Deploy to WSL2 with special handling
ansible-playbook -l wsl.hq playbooks/syncthing.yaml

# 2. Handle WSL2-specific services
ssh verlyn13@100.88.131.44 'systemctl --user enable syncthing'

# 3. Verify 3-node sync
ansible all -m shell -a 'syncthing cli status'
```

### Phase 3.4: Production Configuration
```bash
# 1. Configure selective sync rules
# 2. Set up monitoring and health checks
# 3. Implement backup strategies
# 4. Performance optimization
# 5. Documentation and testing
```

## 📊 Success Metrics

### Functional Requirements
- [ ] Syncthing running on all 3 nodes
- [ ] Bidirectional sync: hetzner ↔ laptop ↔ wsl  
- [ ] Selective sync: work content WSL ↔ hetzner only
- [ ] Conflict resolution working automatically
- [ ] Service auto-restart on node reboot

### Performance Requirements
- [ ] Initial sync completes within 30 minutes
- [ ] File changes sync within 2 minutes
- [ ] Minimal battery impact on laptop
- [ ] Reasonable bandwidth usage

### Operational Requirements
- [ ] Web UI accessible for monitoring
- [ ] Integrated with Ansible management
- [ ] Health checks via monitoring
- [ ] Documentation complete and tested

## 🛠️ Monitoring and Maintenance

### Health Checks
```bash
# Ansible health check playbook
ansible all -m shell -a 'curl -s http://localhost:8384/rest/system/status'

# Service status
ansible all -m systemd -a 'name=syncthing@verlyn13 state=started'

# Sync status
ansible all -m shell -a 'syncthing cli folders list'
```

### Log Management
- Centralized logging via systemd journal
- Log rotation and retention policies
- Error alerting for sync failures

### Backup Strategy
- Configuration backup via Ansible
- Sync folder versioning
- Emergency restore procedures

## 🔄 Rollback Plan

### If Deployment Fails
1. Stop Syncthing services: `ansible all -m systemd -a 'name=syncthing@verlyn13 state=stopped'`
2. Remove configurations: `ansible all -m file -a 'path=/home/verlyn13/.config/syncthing state=absent'`  
3. Uninstall packages: `ansible all -m package -a 'name=syncthing state=absent'`
4. Restore from backup: `git checkout` previous working state

### If Sync Issues Occur
1. Pause problematic folders
2. Resolve conflicts manually
3. Reset folder sync state if needed
4. Resume with clean state

## 📝 Next Actions

1. **Create Syncthing Ansible role structure** ⏳
2. **Implement installation and configuration tasks** ⏳
3. **Deploy to 2-node setup for testing** ⏳
4. **Add WSL2 node and validate 3-way sync** ⏳
5. **Configure production sync rules** ⏳
6. **Implement monitoring and documentation** ⏳

---

**Ready to begin Phase 3 implementation with complete 3-node file synchronization!**