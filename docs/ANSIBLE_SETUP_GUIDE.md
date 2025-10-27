# Ansible Configuration Management Setup

**Last Updated**: 2025-10-27
**Status**: ✅ Operational - All 4 nodes managed via Ansible

> **Related Documentation**: [Infrastructure Status](STATUS.md) | [Node Addition Guide](NODE_ADDITION_GUIDE.md) | [Documentation Index](README.md)

## Overview

This guide covers the Ansible configuration management setup for the mesh infrastructure. All 4 nodes (Hetzner, Laptop, WSL2, MacBook) are currently managed via Ansible from the Hetzner control node.

**Phase 2 Status**: Complete - Configuration management operational across all nodes

## Step 1: Install Ansible on Hetzner (Control Node)

```bash
# On Hetzner (Ubuntu 24.04)
sudo apt update
sudo apt install -y ansible ansible-lint python3-pip
pip3 install netaddr jmespath  # Useful for advanced playbooks

# Verify installation
ansible --version
```

## Step 2: Create Ansible Directory Structure

```bash
# On Hetzner
cd /home/verlyn13
mkdir -p ansible/{inventory,group_vars,host_vars,roles,playbooks,scripts}

# Create the base structure
cat > ansible/ansible.cfg << 'EOF'
[defaults]
inventory = ./inventory/hosts.yaml
host_key_checking = False
remote_user = verlyn13
private_key_file = ~/.ssh/id_ed25519
roles_path = ./roles
vault_password_file = ~/.ansible_vault_pass
interpreter_python = auto_silent
# Use Tailscale IPs for connections
ansible_connection = ssh

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s
pipelining = True
EOF
```

## Step 3: Create Dynamic Inventory

```bash
# Create inventory file that uses Tailscale hostnames
cat > ansible/inventory/hosts.yaml << 'EOF'
all:
  vars:
    ansible_user: verlyn13
    mesh_network: tailscale
    
  children:
    headquarters:
      hosts:
        hetzner.hq:
          ansible_host: hetzner
          public_ip: 91.99.101.204
          roles:
            - hub
            - server
            - exit_node
          always_on: true
    
    workstations:
      hosts:
        laptop.hq:
          ansible_host: laptop
          roaming: true
          roles:
            - workstation
            - development
        
        wsl.hq:
          ansible_host: wsl
          roles:
            - workstation
            - windows_dev
          constraints:
            - no_windows_admin
            - wsl2_networking
      vars:
        workstation_packages:
          - git
          - neovim
          - tmux
          - htop
          - ripgrep
          - fzf
EOF

# Create a dynamic inventory script that queries Tailscale
cat > ansible/scripts/tailscale_inventory.py << 'EOF'
#!/usr/bin/env python3
import json
import subprocess
import sys

def get_tailscale_status():
    """Get Tailscale network status"""
    try:
        result = subprocess.run(
            ['tailscale', 'status', '--json'],
            capture_output=True,
            text=True,
            check=True
        )
        return json.loads(result.stdout)
    except:
        return None

def build_inventory():
    """Build Ansible inventory from Tailscale status"""
    status = get_tailscale_status()
    if not status:
        return {"_meta": {"hostvars": {}}}
    
    inventory = {
        "_meta": {
            "hostvars": {}
        },
        "all": {
            "children": ["tailscale_nodes"]
        },
        "tailscale_nodes": {
            "hosts": []
        }
    }
    
    for peer_id, peer in status.get("Peer", {}).items():
        hostname = peer.get("HostName", peer_id)
        if peer.get("Online", False):
            clean_hostname = hostname.replace("-hq", ".hq")
            inventory["tailscale_nodes"]["hosts"].append(clean_hostname)
            inventory["_meta"]["hostvars"][clean_hostname] = {
                "ansible_host": peer.get("TailscaleIPs", [""])[0],
                "tailscale_hostname": hostname,
                "online": True
            }
    
    return inventory

if __name__ == "__main__":
    print(json.dumps(build_inventory(), indent=2))
EOF

chmod +x ansible/scripts/tailscale_inventory.py
```

## Step 4: Create Group Variables

```bash
# Common variables for all nodes
cat > ansible/group_vars/all.yaml << 'EOF'
---
# Common configuration for all nodes
common_packages:
  - curl
  - wget
  - vim
  - git
  - htop
  - tmux
  - rsync
  - netcat-openbsd
  - dnsutils
  - net-tools

# Timezone configuration
timezone: America/Anchorage

# SSH configuration
ssh_port: 22
ssh_password_authentication: "no"
ssh_permit_root_login: "no"

# Tailscale configuration
tailscale_up_args: "--accept-routes"

# User configuration
primary_user: verlyn13
primary_group: verlyn13
EOF

# Headquarters-specific variables
cat > ansible/group_vars/headquarters.yaml << 'EOF'
---
# Hetzner-specific configuration
firewall_enabled: true
docker_enabled: true

services_to_run:
  - docker
  - tailscaled
  - ssh

advertise_routes:
  - "172.20.0.0/16"  # Infisical network
  
exit_node: true
EOF

# Workstation-specific variables
cat > ansible/group_vars/workstations.yaml << 'EOF'
---
# Workstation configuration
development_tools:
  - build-essential
  - python3-pip
  - nodejs
  - npm
  - golang
  - rustc
  - cargo

gui_tools_enabled: false  # Set to true for laptop
EOF
```

## Step 5: Create Essential Roles

```bash
# Create base role structure
mkdir -p ansible/roles/{common,tailscale,security,docker,development}/{tasks,handlers,templates,files,vars,defaults}

# Common role - baseline configuration
cat > ansible/roles/common/tasks/main.yaml << 'EOF'
---
- name: Update package cache
  package:
    update_cache: yes
  when: ansible_os_family == "Debian"
  
- name: Update package cache (Fedora)
  dnf:
    update_cache: yes
  when: ansible_distribution == "Fedora"

- name: Install common packages
  package:
    name: "{{ common_packages }}"
    state: present

- name: Set timezone
  timezone:
    name: "{{ timezone }}"
  notify: restart cron

- name: Ensure primary user exists
  user:
    name: "{{ primary_user }}"
    group: "{{ primary_group }}"
    shell: /bin/bash
    groups: wheel,docker
    append: yes
  when: ansible_os_family == "RedHat"

- name: Configure sudo for primary user
  lineinfile:
    path: /etc/sudoers.d/{{ primary_user }}
    line: "{{ primary_user }} ALL=(ALL) NOPASSWD:ALL"
    create: yes
    validate: 'visudo -cf %s'
EOF

# Tailscale role
cat > ansible/roles/tailscale/tasks/main.yaml << 'EOF'
---
- name: Check if Tailscale is installed
  command: which tailscale
  register: tailscale_check
  ignore_errors: yes
  changed_when: false

- name: Install Tailscale (Debian/Ubuntu)
  block:
    - name: Add Tailscale GPG key
      get_url:
        url: https://pkgs.tailscale.com/stable/ubuntu/noble.noarmor.gpg
        dest: /usr/share/keyrings/tailscale-archive-keyring.gpg
    
    - name: Add Tailscale repository
      apt_repository:
        repo: "deb [signed-by=/usr/share/keyrings/tailscale-archive-keyring.gpg] https://pkgs.tailscale.com/stable/ubuntu noble main"
        state: present
    
    - name: Install Tailscale package
      apt:
        name: tailscale
        state: present
        update_cache: yes
  when: 
    - tailscale_check.rc != 0
    - ansible_os_family == "Debian"

- name: Install Tailscale (Fedora)
  block:
    - name: Add Tailscale repository
      yum_repository:
        name: tailscale-stable
        description: Tailscale stable
        baseurl: https://pkgs.tailscale.com/stable/fedora/$basearch
        gpgkey: https://pkgs.tailscale.com/stable/fedora/repo.gpg
        enabled: yes
        gpgcheck: yes
    
    - name: Install Tailscale package
      dnf:
        name: tailscale
        state: present
  when:
    - tailscale_check.rc != 0  
    - ansible_distribution == "Fedora"

- name: Enable and start tailscaled
  systemd:
    name: tailscaled
    state: started
    enabled: yes

- name: Check Tailscale status
  command: tailscale status --json
  register: tailscale_status
  changed_when: false
  ignore_errors: yes
EOF

# Security role
cat > ansible/roles/security/tasks/main.yaml << 'EOF'
---
- name: Configure SSH
  lineinfile:
    path: /etc/ssh/sshd_config
    regexp: "^{{ item.key }}"
    line: "{{ item.key }} {{ item.value }}"
    state: present
  with_items:
    - { key: "PasswordAuthentication", value: "{{ ssh_password_authentication }}" }
    - { key: "PermitRootLogin", value: "{{ ssh_permit_root_login }}" }
    - { key: "Port", value: "{{ ssh_port }}" }
  notify: restart sshd

- name: Configure firewall (Ubuntu)
  ufw:
    rule: allow
    port: "{{ item }}"
  with_items:
    - "{{ ssh_port }}"
    - "41641"  # Tailscale
  when: 
    - ansible_os_family == "Debian"
    - firewall_enabled | default(false)

- name: Enable UFW
  ufw:
    state: enabled
  when:
    - ansible_os_family == "Debian"
    - firewall_enabled | default(false)

- name: Set up fail2ban
  package:
    name: fail2ban
    state: present
  when: ansible_system == "Linux"
EOF

# Create handlers
cat > ansible/roles/common/handlers/main.yaml << 'EOF'
---
- name: restart cron
  service:
    name: "{{ 'cron' if ansible_os_family == 'Debian' else 'crond' }}"
    state: restarted
EOF

cat > ansible/roles/security/handlers/main.yaml << 'EOF'
---
- name: restart sshd
  service:
    name: sshd
    state: restarted
EOF
```

## Step 6: Create Main Playbooks

```bash
# Site-wide playbook
cat > ansible/playbooks/site.yaml << 'EOF'
---
- name: Configure all nodes
  hosts: all
  become: yes
  roles:
    - common
    - security
    - tailscale

- name: Configure headquarters
  hosts: headquarters
  become: yes
  tasks:
    - name: Configure as exit node
      command: tailscale up --advertise-exit-node --advertise-routes={{ advertise_routes | join(',') }}
      when: exit_node | default(false)

- name: Configure workstations
  hosts: workstations
  become: yes
  tasks:
    - name: Accept routes from exit node
      command: tailscale up --accept-routes --exit-node-allow-lan-access
EOF

# Bootstrap playbook for new nodes
cat > ansible/playbooks/bootstrap.yaml << 'EOF'
---
- name: Bootstrap new node
  hosts: "{{ target_host }}"
  become: yes
  gather_facts: no
  tasks:
    - name: Wait for system to become reachable
      wait_for_connection:
        timeout: 60
    
    - name: Gather facts
      setup:
    
    - name: Run common role
      include_role:
        name: common
    
    - name: Run security role
      include_role:
        name: security
    
    - name: Install and configure Tailscale
      include_role:
        name: tailscale
EOF

# Quick sync playbook
cat > ansible/playbooks/sync-configs.yaml << 'EOF'
---
- name: Sync configurations across nodes
  hosts: all
  become: yes
  tasks:
    - name: Ensure /etc/mesh-config directory exists
      file:
        path: /etc/mesh-config
        state: directory
        mode: '0755'
    
    - name: Template network configuration
      template:
        src: ../templates/network-config.j2
        dest: /etc/mesh-config/network.conf
      tags: network
    
    - name: Sync user dotfiles
      synchronize:
        src: /home/{{ primary_user }}/.bashrc
        dest: /home/{{ primary_user }}/.bashrc
        mode: pull
      delegate_to: hetzner.hq
      tags: dotfiles
EOF
```

## Step 7: Create Helper Scripts

```bash
# Ansible wrapper script
cat > ansible/run-ansible.sh << 'EOF'
#!/bin/bash
# Ansible execution wrapper with common options

PLAYBOOK=${1:-playbooks/site.yaml}
LIMIT=${2:-all}
TAGS=${3:-}

cd /home/verlyn13/ansible

# Check if nodes are reachable
echo "Checking node connectivity..."
ansible all -m ping --one-line

echo "Running playbook: $PLAYBOOK"
if [ -n "$TAGS" ]; then
    ansible-playbook "$PLAYBOOK" --limit "$LIMIT" --tags "$TAGS"
else
    ansible-playbook "$PLAYBOOK" --limit "$LIMIT"
fi
EOF
chmod +x ansible/run-ansible.sh

# Node health check script
cat > ansible/check-nodes.sh << 'EOF'
#!/bin/bash
# Quick health check of all nodes

echo "=== Tailscale Status ==="
tailscale status

echo -e "\n=== Ansible Connectivity ==="
cd /home/verlyn13/ansible
ansible all -m ping

echo -e "\n=== System Info ==="
ansible all -m setup -a "filter=ansible_hostname,ansible_distribution,ansible_kernel" --one-line
EOF
chmod +x ansible/check-nodes.sh
```

## Step 8: Initialize and Test

```bash
# Initialize SSH keys if not present
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N "" -C "ansible@hetzner.hq"

# Copy SSH key to other nodes (run from Hetzner)
ssh-copy-id verlyn13@laptop.hq
# ssh-copy-id verlyn13@wsl.hq  # When WSL is connected

# Test connectivity
cd /home/verlyn13/ansible
ansible all -m ping

# Run initial configuration
ansible-playbook playbooks/site.yaml

# Check results
./check-nodes.sh
```

## Step 9: Set Up Git Repository

```bash
cd /home/verlyn13/ansible
git init
cat > .gitignore << 'EOF'
*.retry
*.pyc
__pycache__
.vault_pass
vault.yaml
*.key
*.pem
host_vars/*/vault.yaml
EOF

git add .
git commit -m "Initial Ansible configuration for mesh network"

# Optional: Set up remote
# git remote add origin <your-git-repo>
# git push -u origin main
```

## Usage Examples

```bash
# Run full configuration on all nodes
./run-ansible.sh

# Configure only workstations
./run-ansible.sh playbooks/site.yaml workstations

# Run only security updates
./run-ansible.sh playbooks/site.yaml all security

# Bootstrap the WSL node when ready
ansible-playbook playbooks/bootstrap.yaml -e target_host=wsl.hq

# Ad-hoc commands
ansible all -a "uptime"
ansible workstations -m package -a "name=neovim state=present" --become
```

## Next Steps

1. **Add More Roles**:
   - `syncthing` - File synchronization
   - `docker` - Container management
   - `monitoring` - Prometheus/Grafana
   - `backup` - Automated backups

2. **Implement Secrets Management**:
   ```bash
   # Create vault file
   ansible-vault create group_vars/all/vault.yaml
   # Edit existing file
   ansible-vault edit group_vars/all/vault.yaml
   ```

3. **Set Up Continuous Deployment**:
   - Webhook from Git to trigger Ansible
   - Scheduled runs via cron/systemd timers
   - Compliance checking playbooks

4. **Create Node-Specific Configurations**:
   ```bash
   # For special WSL handling
   cat > host_vars/wsl.hq.yaml << 'EOF'
   ansible_connection: ssh
   ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
   wsl_specific: true
   EOF
   ```

## Troubleshooting

```bash
# Debug connection issues
ansible all -m ping -vvv

# Check inventory
ansible-inventory --list

# Dry run
ansible-playbook playbooks/site.yaml --check

# Run with specific module
ansible all -m setup -a "filter=ansible_default_ipv4"

# Test dynamic inventory
python3 scripts/tailscale_inventory.py
```
