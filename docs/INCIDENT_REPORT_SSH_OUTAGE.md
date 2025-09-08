# Incident Report: SSH Outage During Hetzner Deployment

## Summary

**Date**: 2025-09-08  
**Duration**: ~2 hours  
**Affected Service**: SSH access to hetzner-hq (91.99.101.204)  
**Impact**: Complete SSH lockout, requiring console recovery  
**Root Cause**: Dangerous wildcard sudo permissions  
**Resolution**: Console access, sudoers fix, service restored  

## Timeline

| Time (UTC) | Event |
|------------|-------|
| 19:00 | Begin mesh-ops deployment to Hetzner |
| 19:30 | Execute create-mesh-user script with dangerous sudoers |
| 19:45 | **SSH access lost** - both ports 22 and 2222 |
| 19:50 | Confirm network connectivity (ping works) |
| 20:00 | Identify root cause: wildcard systemctl permissions |
| 20:15 | Access Hetzner Cloud Console |
| 20:30 | Enter rescue mode, mount filesystem |
| 20:45 | Fix sudoers file, remove dangerous wildcards |
| 21:00 | Restart SSH service |
| 21:17 | **SSH access restored**, deployment complete |

## Root Cause Analysis

### Dangerous Sudo Configuration
The deployment script created this sudoers configuration:
```bash
# /etc/sudoers.d/mesh-ops (DANGEROUS VERSION)
mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/systemctl start *
mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/systemctl stop *
mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart *
```

### What Happened
1. mesh-ops user was created with these wildcard permissions
2. During testing or script execution, a command caused SSH service to stop
3. The `systemctl stop *` wildcard allowed mesh-ops to stop **any** systemd service
4. SSH daemon (sshd) was stopped, locking out all remote access

### Why This Was Catastrophic
- **No service specificity**: Wildcards matched critical services like sshd
- **No protection for SSH**: Nothing prevented stopping the SSH daemon
- **Complete lockout**: Both user (port 2222) and root (port 22) SSH stopped
- **Production server**: Critical services like Infisical were at risk

## Recovery Process

### 1. Hetzner Console Access
- Accessed: https://console.hetzner.cloud
- Used VNC console with password: `3cdkcp9bmbtd`
- Gained root shell access

### 2. Filesystem Analysis
```bash
# In rescue mode
mount /dev/sda1 /mnt
chroot /mnt
systemctl status sshd  # Confirmed stopped
```

### 3. Sudoers Fix
```bash
# Removed dangerous file
rm /etc/sudoers.d/mesh-ops

# Created safe replacement
cat > /etc/sudoers.d/mesh-ops << 'EOF'
# mesh-ops - PRODUCTION READ-ONLY VERSION
mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/docker ps
mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/docker logs -n 50 *
mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/journalctl -n 100
mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/tailscale status
# NO SYSTEMCTL PERMISSIONS - READ ONLY ACCESS ONLY
EOF

# Validate syntax
visudo -c -f /etc/sudoers.d/mesh-ops
```

### 4. SSH Restoration
```bash
# Ensure SSH config allows mesh-ops
echo "AllowUsers verlyn13 mesh-ops" >> /etc/ssh/sshd_config

# Restart SSH service
systemctl restart sshd
systemctl enable sshd

# Verify service running
systemctl status sshd
ss -tlnp | grep :2222
```

## Security Lessons Learned

### 1. Never Use Wildcards for Critical Services
❌ **DANGEROUS**:
```bash
systemctl stop *    # Can stop SSH!
systemctl start *   # Can disrupt services!
systemctl * ssh*    # Direct SSH control!
```

✅ **SAFE**:
```bash
systemctl restart tailscaled  # Specific service
systemctl --user *           # User scope only
```

### 2. Production Server Constraints
Production servers require different security models:
- **Read-only monitoring** instead of service control
- **Specific service permissions** instead of wildcards  
- **User-space operations** instead of system administration
- **Multiple access methods** for recovery

### 3. Always Validate Sudoers
```bash
# Always test before deployment
visudo -c -f /etc/sudoers.d/new-file

# Never deploy untested sudoers rules to production
```

## Preventive Measures Implemented

### 1. Fixed All Scripts
Updated all mesh-ops deployment scripts to remove dangerous patterns:
- `create-mesh-user.sh` - No wildcards for system services
- Sudoers templates - Specific service names only
- Added validation script: `validate-sudoers-safety.sh`

### 2. Security Documentation
Created comprehensive security safeguards:
- `SECURITY_SAFEGUARDS.md` - Complete best practices
- Dangerous pattern identification
- Safe pattern examples

### 3. Production Model for Hetzner
Established different permission model for production:
- **mesh-ops on WSL/Laptop**: Full development permissions
- **mesh-ops on Hetzner**: Read-only monitoring only

### 4. Emergency Procedures
- Documented console access procedures
- Created recovery scripts
- Established incident response protocol

## Impact Assessment

### Services Affected
- ✅ **Infisical**: Remained accessible via Cloudflare tunnel
- ✅ **Docker containers**: Continued running normally  
- ✅ **Tailscale mesh**: Network connectivity maintained
- ❌ **SSH access**: Complete remote lockout for 2 hours

### Business Continuity
- **No data loss**: All services and data preserved
- **No downtime for users**: Web services remained available
- **Management access only**: Only affected remote administration

## Action Items Completed

- [x] Fix all deployment scripts to remove wildcards
- [x] Create sudoers validation script
- [x] Document security best practices
- [x] Update incident response procedures
- [x] Test recovery process
- [x] Establish production security model

## Recommendations

1. **Always test in non-production first**
2. **Use specific service names in sudoers**
3. **Maintain console access credentials**
4. **Different security models for different environments**
5. **Regular sudoers audits**

---

**Status**: Resolved ✅  
**Next Review**: 30 days post-incident  
**Documentation**: All procedures updated in mesh-infra repository