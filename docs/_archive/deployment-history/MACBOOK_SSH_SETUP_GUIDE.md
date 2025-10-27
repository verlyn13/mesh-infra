# MacBook SSH Setup Guide
**Complete Bidirectional Access for Mesh Network**

Date: 2025-10-18
Status: In Progress

## 🎯 Goal

Enable full two-way SSH access between MacBook and all mesh nodes, particularly the Fedora laptop for seamless development workflows.

## ✅ Completed

- [x] Tailscale mesh network joined (100.122.121.37)
- [x] SSH connectivity from MacBook → Hetzner working
- [x] MacBook public key added to Hetzner
- [x] SSH config created for all mesh nodes (`~/.ssh/conf.d/mesh.conf`)
- [x] Helper script created (`scripts/setup-macbook-ssh.sh`)

## 🔧 Required Manual Steps

### 1. Enable SSH on MacBook

```bash
# Run this on MacBook
sudo systemsetup -setremotelogin on

# Verify it's enabled
sudo systemsetup -getremotelogin
# Should show: Remote Login: On
```

### 2. Add MacBook's Public Key to Fedora Laptop

**On Fedora Laptop**, run:
```bash
# Add MacBook's public key
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICN0hMC4yigFIck+L9op4HPb4AWDaZR+dqc/aRzdywmG jeffreyverlynjohnson@gmail.com" >> ~/.ssh/authorized_keys

# Verify it was added
tail -1 ~/.ssh/authorized_keys
```

### 3. Add MacBook's Public Key to WSL2 (Optional)

**On WSL2**, run:
```bash
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICN0hMC4yigFIck+L9op4HPb4AWDaZR+dqc/aRzdywmG jeffreyverlynjohnson@gmail.com" >> ~/.ssh/authorized_keys
```

### 4. Add Laptop's Public Key to MacBook

**On Fedora Laptop**, get the public key:
```bash
cat ~/.ssh/id_ed25519.pub
```

**On MacBook**, add it:
```bash
echo "<paste-laptop-public-key-here>" >> ~/.ssh/authorized_keys

# Create ~/.ssh/authorized_keys if it doesn't exist
mkdir -p ~/.ssh
chmod 700 ~/.ssh
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

### 5. Verify Connectivity

**From MacBook**:
```bash
# Test SSH to laptop
ssh laptop-hq whoami
# Should return: verlyn13

# Test SSH to Hetzner (already working)
ssh hetzner-hq whoami
# Should return: verlyn13

# Test SSH to WSL (if configured)
ssh wsl-hq whoami
```

**From Laptop** (test reverse):
```bash
# Test SSH to MacBook
ssh verlyn13@100.122.121.37 whoami
# Should return: verlyn13

# Or if you add to laptop's SSH config:
# Host macbook-hq
#   HostName 100.122.121.37
#   User verlyn13
#
# Then: ssh macbook-hq whoami
```

## 📋 Automated Setup Script

Run the helper script for guided setup:

```bash
cd ~/Development/personal/mesh-infra
./scripts/setup-macbook-ssh.sh
```

This script will:
1. Enable SSH Remote Login on MacBook
2. Show MacBook's public key for distribution
3. Test connectivity to all nodes
4. Provide step-by-step guidance

## 🔑 SSH Configuration Created

### MacBook's SSH Config

New file: `~/.ssh/conf.d/mesh.conf`

Quick access shortcuts:
```bash
ssh hetzner-hq    # Hetzner hub
ssh laptop-hq     # Fedora laptop
ssh laptop        # Alias for laptop
ssh wsl-hq        # WSL2 node
ssh wsl           # Alias for WSL
```

### Key Files

| File | Purpose |
|------|---------|
| `~/.ssh/id_ed25519` | MacBook's private key (default) |
| `~/.ssh/id_ed25519.pub` | MacBook's public key (distribute to other nodes) |
| `~/.ssh/config` | Main SSH config (includes conf.d) |
| `~/.ssh/conf.d/mesh.conf` | Mesh-specific host configurations |
| `~/.ssh/conf.d/hetzner.conf` | Hetzner server configurations |

## 🎯 Current Network Status

All nodes on Tailscale mesh:

| Node | Tailscale IP | SSH Status |
|------|--------------|------------|
| **MacBook** | 100.122.121.37 | ⏳ Needs Remote Login enabled |
| **Hetzner** | 100.84.151.58 | ✅ Working |
| **Laptop** | 100.84.2.8 | ⏳ Needs MacBook key |
| **WSL2** | 100.88.131.44 | ⏳ Needs MacBook key |

## 🚀 After SSH is Working

Once SSH is bidirectional, you can:

### 1. Test Ansible from Hetzner

```bash
# SSH to Hetzner
ssh hetzner-hq

# If mesh-infra is on Hetzner:
cd mesh-infra/ansible
ansible macbook.hq -m ping
ansible laptop.hq -m ping
ansible all -m ping
```

### 2. File Transfer

```bash
# Copy files from MacBook to laptop
scp ~/file.txt laptop-hq:~/

# Copy from laptop to MacBook
scp laptop-hq:~/remote-file.txt ~/

# Rsync for directories
rsync -avz ~/project/ laptop-hq:~/project/
```

### 3. Remote Development

```bash
# SSH to laptop and work there
ssh laptop-hq

# Or use VSCode Remote SSH
# Install "Remote - SSH" extension
# Connect to: laptop-hq
```

### 4. Run Commands Remotely

```bash
# Check laptop status
ssh laptop-hq 'tailscale status'

# Run commands on all nodes
for node in hetzner-hq laptop-hq; do
  echo "=== $node ==="
  ssh $node 'uname -a'
done
```

## 🔍 Troubleshooting

### SSH Permission Denied

```bash
# Check SSH service is running on target
ssh target-host 'systemctl status sshd'

# Check key is in authorized_keys
ssh target-host 'cat ~/.ssh/authorized_keys | grep MacBook'

# Test with verbose output
ssh -vvv laptop-hq
```

### Can't Connect to MacBook

```bash
# On MacBook, check SSH service
sudo launchctl list | grep sshd

# Check firewall
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate

# Test localhost first
ssh localhost whoami
```

### Wrong Permissions

```bash
# Fix SSH directory permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
```

## 📝 Quick Reference

### MacBook Public Key
```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICN0hMC4yigFIck+L9op4HPb4AWDaZR+dqc/aRzdywmG jeffreyverlynjohnson@gmail.com
```

### Tailscale IPs
```
Hetzner: 100.84.151.58
Laptop:  100.84.2.8
WSL2:    100.88.131.44
MacBook: 100.122.121.37
```

### Quick Commands
```bash
# View all mesh nodes
tailscale status

# Test ping to all nodes
for ip in 100.84.151.58 100.84.2.8 100.88.131.44; do
  ping -c 1 $ip && echo "✓ $ip reachable"
done

# SSH to all nodes
ssh hetzner-hq whoami
ssh laptop-hq whoami
ssh wsl-hq whoami
```

---

**Next Step**: Run `sudo systemsetup -setremotelogin on` and add keys as shown above, then test with `ssh laptop-hq whoami`
