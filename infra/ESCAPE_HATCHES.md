# Emergency Access Procedures

## When Mesh VPN is Down

### 1. Direct SSH to Hetzner (Primary)
```bash
ssh verlyn13@91.99.101.204 -p 2222
```

### 2. WireGuard Fallback (Secondary)
```bash
# If Tailscale fails, use pre-configured WireGuard
sudo wg-quick up /path/to/infra/backup/wg/emergency.conf
```

### 3. Hetzner Console (Last Resort)
- Login to Hetzner Cloud Console
- Use VNC console access
- Reset networking if needed

## Recovery Procedures

### Restart Tailscale
```bash
# On Hetzner
sudo systemctl restart tailscaled
sudo tailscale up --advertise-exit-node --advertise-routes=172.20.0.0/16

# On clients
sudo systemctl restart tailscaled
sudo tailscale up --accept-routes
```

### Check Firewall Rules
```bash
# Verify emergency SSH is accessible
sudo ufw status
sudo iptables -L -n | grep 2222
```

### Network Diagnostics
```bash
# Test connectivity
tailscale ping hetzner-hq
tailscale netcheck

# Check routes
ip route show table all | grep tailscale
```

## Important IPs
- Hetzner Public: 91.99.101.204
- Mesh Network: 10.0.0.0/24
  - Hetzner: 10.0.0.1
  - Laptop: 10.0.0.2
  - WSL: 10.0.0.3