# Node Addition Guide
**Scalable Procedures for Mesh Network Expansion**

*Updated: 2025-10-27*
*Status: All 4 planned nodes deployed*

> **Related Documentation**: [Infrastructure Status](STATUS.md) | [Ansible Setup Guide](ANSIBLE_SETUP_GUIDE.md) | [Documentation Index](README.md)

## 🎯 Purpose

Standardized procedures for adding new nodes to the mesh infrastructure, ensuring consistent security, configuration, and integration across all environments.

**Current Status**: All 4 originally planned nodes successfully deployed (Hetzner, Laptop, WSL2, MacBook). This guide remains available for future node additions.

## 📋 Node Addition Checklist

### Pre-Addition Requirements
- [ ] **Target System Access**: Admin/sudo rights (or documented limitations)
- [ ] **Network Connectivity**: Internet access for initial setup
- [ ] **Repository Access**: Git clone capabilities
- [ ] **SSH Key Material**: Access to mesh SSH keys

### Supported Node Types

#### 🖥️ Standard Linux Nodes
- **Examples**: Fedora, Ubuntu, Debian workstations/servers
- **Requirements**: Full sudo access, systemd, package manager
- **Complexity**: Low
- **Automation**: Full Ansible support

#### 🪟 WSL2 Nodes (Special Procedures)
- **Examples**: Fedora WSL2, Ubuntu WSL2
- **Requirements**: WSL2 environment, limited Windows permissions
- **Complexity**: Medium
- **Automation**: Ansible with constraints
- **Special Considerations**:
  - Tailscale userspace networking mode
  - systemd may be limited or unavailable
  - Corporate network restrictions possible
  - Windows host firewall considerations

#### 🍎 macOS Nodes (Future)
- **Examples**: MacBook Air, Mac Studio
- **Requirements**: Homebrew, admin rights
- **Complexity**: Medium
- **Automation**: Limited Ansible support

#### ☁️ Cloud Nodes (Future)
- **Examples**: Additional Hetzner, AWS, GCP instances
- **Requirements**: Cloud provider access, SSH keys
- **Complexity**: Low-Medium
- **Automation**: Full support with provider-specific roles

## 🚀 Standard Addition Procedure

### Phase 1: Network Integration
```bash
# 1. Install Tailscale on target node
# (Node-specific installation steps)

# 2. Join mesh network
sudo tailscale up --accept-routes --hostname=<node-name>-hq --accept-dns=true

# 3. Verify connectivity from control node
tailscale ping <new-node-ip>
ssh verlyn13@<new-node-ip>
```

### Phase 2: Ansible Integration
```bash
# 4. Add to inventory (on Hetzner control node)
# Edit ansible/inventory/hosts.yaml:
<node-name>.hq:
  ansible_host: <tailscale-ip>
  ansible_user: verlyn13

# 5. Test Ansible connectivity
ansible <node-name>.hq -m ping

# 6. Apply baseline configuration
ansible-playbook -l <node-name>.hq playbooks/site.yaml
```

### Phase 3: Service Integration
```bash
# 7. Deploy services as needed
ansible-playbook -l <node-name>.hq playbooks/install-tools.yaml

# 8. Configure Syncthing (Phase 3)
# (Will be automated via ansible/roles/syncthing)
```

## 🪟 WSL2 Node Special Procedures

### Pre-Requirements for WSL2
- Windows 10/11 with WSL2 enabled
- Fedora WSL2 distribution installed
- Basic Linux utilities available

### WSL2-Specific Steps

#### 1. Tailscale Installation (Userspace Mode)
```bash
# WSL2 requires userspace networking due to Windows limitations
curl -fsSL https://pkgs.tailscale.com/stable/fedora/tailscale.repo | sudo tee /etc/yum.repos.d/tailscale.repo
sudo dnf install -y tailscale

# Start in userspace mode (required for WSL2)
sudo tailscale up --accept-routes --hostname=wsl-hq --accept-dns=true --userspace-networking
```

#### 2. Ansible Limitations & Workarounds
```yaml
# ansible/inventory/hosts.yaml - WSL2 specific vars
wsl.hq:
  ansible_host: <wsl-tailscale-ip>
  ansible_user: verlyn13
  # WSL2-specific variables
  wsl2_environment: true
  systemd_available: false  # May be limited
  package_manager: dnf
  corporate_network: true
```

#### 3. Service Adaptations
- **Systemd Services**: May need manual start scripts
- **Network Services**: Corporate firewall considerations
- **File Permissions**: Windows filesystem integration quirks
- **Process Management**: Different from standard Linux

## 📊 Integration Validation

### Connectivity Tests
```bash
# From control node (Hetzner)
ansible <new-node> -m setup -a 'filter=ansible_hostname'
ansible <new-node> -m ping
tailscale ping <new-node-ip>

# Network services test
ansible <new-node> -m shell -a 'curl -s http://100.84.151.58:8080/health || echo "Service unreachable"'
```

### Configuration Verification
```bash
# Security baseline
ansible <new-node> -m shell -a 'sudo iptables -L | grep -c "DROP\|REJECT"'

# File permissions
ansible <new-node> -m file -a 'path=/home/verlyn13/.ssh/authorized_keys state=file'

# Service status
ansible <new-node> -m systemd -a 'name=tailscaled state=started enabled=yes'
```

## 🛠️ Tomorrow's WSL2 Deployment Plan

### Preparation (Tonight)
- [x] Document WSL2 constraints and requirements
- [x] Update inventory template for WSL2 node
- [x] Prepare userspace networking documentation
- [x] Create WSL2-specific Ansible variables

### Deployment (Tomorrow at Work PC)
- [ ] Install/update Fedora WSL2 if needed
- [ ] Install Tailscale with userspace networking
- [ ] Join mesh as `wsl-hq`
- [ ] Test connectivity from other nodes
- [ ] Add to Ansible inventory
- [ ] Apply baseline configuration (adapted for WSL2)
- [ ] Validate integration and document any issues

### Post-Deployment
- [ ] Update facts.yml with WSL2 deployment status
- [ ] Document any WSL2-specific operational considerations
- [ ] Test Phase 3 readiness with all 3 nodes
- [ ] Update roadmap for complete 3-node operations

## 🔐 Security Considerations

### Node-Specific Security
- **SSH Keys**: Same ansible_ed25519 key across all nodes
- **Firewall Rules**: Adapted per node environment
- **Corporate Networks**: May require additional documentation
- **Windows Integration**: WSL2 security boundary considerations

### Access Control
- All nodes use same `verlyn13` user for consistency
- Ansible automation maintains security baselines
- Emergency access procedures documented per node type

## 📝 Documentation Updates Required

After each node addition:
1. Update `docs/_grounding/facts.yml`
2. Update `ansible/inventory/hosts.yaml`
3. Run `make probe` to update repository snapshot
4. Test all Makefile targets with new node

---

**Ready for WSL2 node addition tomorrow. All procedures documented and tested.**