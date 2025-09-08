# Security Safeguards for Mesh-Ops Implementation

## Critical Incident: SSH Lockout on Hetzner

### What Happened
During Phase 2.8 deployment to Hetzner, we lost SSH access immediately after creating the mesh-ops user. The root cause was dangerous wildcard sudo permissions that allowed mesh-ops to stop ANY systemd service, including SSH.

### Root Cause
The sudoers file contained:
```bash
# DANGEROUS - NEVER DO THIS!
mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/systemctl stop *
mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/systemctl start *
mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart *
```

These wildcards meant mesh-ops could stop sshd, locking us out of the server.

## Security Safeguards Implemented

### 1. No Wildcard Systemctl Permissions

**NEVER use wildcards for system service control:**

❌ **BAD - Dangerous:**
```bash
mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/systemctl stop *
mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart *
mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/systemctl * sshd
```

✅ **GOOD - Safe:**
```bash
# Specific services only
mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart tailscaled
mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart nginx

# User scope is safe (can't affect system services)
mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/systemctl --user *
```

### 2. Protected Services List

These services must NEVER be controllable by mesh-ops:
- `sshd` / `ssh` - Remote access
- `networking` / `NetworkManager` - Network connectivity
- `systemd-resolved` - DNS resolution
- `firewalld` / `ufw` - Firewall (without specific rules)

### 3. Validation Script

Run `validate-sudoers-safety.sh` before applying any sudoers configuration:
```bash
./scripts/validate-sudoers-safety.sh
```

This script checks for:
- Dangerous wildcard patterns
- SSH service exposure
- Process killing permissions
- System shutdown/reboot access

### 4. Sudoers Template Rules

All sudoers templates now follow these rules:

1. **Be Specific**: Name exact services that can be controlled
2. **Use Full Paths**: Always use `/usr/bin/systemctl` not just `systemctl`
3. **Scope User Services**: Use `--user` flag for user-level services
4. **Document Safety**: Add comments explaining why rules are safe
5. **Validate Before Apply**: Always run `visudo -c` before deployment

### 5. Emergency Recovery Plan

If SSH access is lost:

1. **Hetzner Console**: Use web console at https://console.hetzner.cloud
2. **Recovery Mode**: Boot into rescue system
3. **Fix Sudoers**: Mount disk and remove problematic sudoers file
4. **Backup Access**: Keep emergency root console access documented

### 6. Testing Protocol

Before deploying to production (Hetzner):

1. Test on local VM first
2. Validate sudoers with safety script
3. Have console access ready
4. Create snapshot before changes
5. Test with non-critical service first

## Sudoers Best Practices

### Safe Patterns

```bash
# Specific service control
mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart tailscaled
mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/systemctl status tailscaled

# User systemd (can't affect system)
mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/systemctl --user *

# Specific loginctl operations
mesh-ops ALL=(ALL) NOPASSWD: /bin/loginctl enable-linger mesh-ops
mesh-ops ALL=(ALL) NOPASSWD: /bin/loginctl disable-linger mesh-ops

# Package management (safe - can't stop services)
mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/apt install -y *
mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/dnf install -y *
```

### Dangerous Patterns to Avoid

```bash
# NEVER - Can kill SSH
mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/systemctl stop *
mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/systemctl * ssh*
mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/service * stop

# NEVER - Can kill processes
mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/killall *
mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/pkill *

# NEVER - Full sudo
mesh-ops ALL=(ALL) NOPASSWD: ALL

# NEVER - System control
mesh-ops ALL=(ALL) NOPASSWD: /sbin/shutdown *
mesh-ops ALL=(ALL) NOPASSWD: /sbin/reboot
```

## Verification Checklist

Before deploying mesh-ops to any node:

- [ ] Run `validate-sudoers-safety.sh`
- [ ] No wildcards in systemctl rules
- [ ] SSH service not mentioned in sudoers
- [ ] Console access available as backup
- [ ] Snapshot/backup created
- [ ] Test in non-production first

## Lessons Learned

1. **Wildcards are dangerous**: Even with good intentions, wildcards in sudo rules can have catastrophic effects
2. **User scope is safer**: `systemctl --user` can't affect system services
3. **Be explicit**: Name every service that needs control
4. **Test thoroughly**: Always test in safe environment first
5. **Have backups**: Multiple access methods prevent total lockout

---

*This document is critical for preventing SSH lockouts and maintaining secure access to mesh infrastructure.*