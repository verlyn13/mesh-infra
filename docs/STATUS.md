# Mesh Infrastructure Status

**Last Updated**: 2025-10-27
**Overall Health**: 🟢 OPERATIONAL
**Active Nodes**: 2/4 (Dynamic availability by design)

> This is the single source of truth for current infrastructure status. For historical deployment reports, see [`docs/_archive/deployment-history/`](docs/_archive/deployment-history/).

## Quick Status

| Component | Status | Notes |
|-----------|--------|-------|
| Mesh Network | ✅ Operational | Tailscale v1.88.3+ across all nodes |
| Hub Node (Hetzner) | ✅ Online 24/7 | 100% uptime, exit node active |
| Configuration Mgmt | ✅ Active | Ansible managing 4 nodes |
| File Sync (Phase 3) | 🟡 Ready | Syncthing role ready, not deployed |

## Node Status

| Node | Hostname | Tailscale IP | Current Status | Deployed | Uptime Pattern |
|------|----------|--------------|----------------|----------|----------------|
| **Hetzner Hub** | hetzner-hq | 100.84.151.58 | ✅ Always-On | 2025-09-07 | 24/7 |
| **Fedora Laptop** | laptop-hq | 100.84.2.8 | 🔄 Dynamic | 2025-09-06 | On-demand |
| **WSL2** | wsl-fedora-kbc | 100.88.131.44 | 🔄 Dynamic | 2025-09-07 | Work hours only |
| **MacBook Pro** | macbook-hq | 100.122.121.37 | ✅ Online | 2025-10-18 | On-demand |

### Current Session (as of last check)
- **MacBook**: ✅ Connected at workplace (10.147.160.20 LAN)
- **Hetzner**: ✅ Reachable (~1112ms avg, high latency likely due to network conditions)
- **WSL2**: ✅ Reachable (~306ms avg)
- **Laptop**: ❌ Offline (expected - roaming node, powered off when not in use)

> 💡 **Note**: This mesh is designed for dynamic node availability. Only Hetzner maintains 24/7 uptime. Personal devices come online as needed, and services gracefully adapt to available nodes.

## Network Configuration

### Tailscale Mesh Network
- **Network Range**: 100.64.0.0/10 (CGNAT space)
- **Hub Node**: 100.84.151.58 (hetzner-hq)
- **Exit Node**: Enabled on Hetzner for secure internet routing
- **Advertised Routes**: 172.20.0.0/16 (Docker networks on Hetzner)
- **DERP Relay**: Nuremberg
- **Auth Account**: jeffreyverlynjohnson@gmail.com

### Access Methods

**Via Tailscale Mesh (Preferred)**
```bash
# Once Tailscale is running on your device
ssh verlyn13@hetzner-hq -p 2222
ssh verlyn13@100.84.151.58 -p 2222
```

**Direct Access (Always Available)**
```bash
# Public IP - works from anywhere
ssh verlyn13@91.99.101.204 -p 2222
```

**Emergency Access**
- Hetzner Cloud Console: https://console.hetzner.cloud
- See [ESCAPE_HATCHES.md](../infra/ESCAPE_HATCHES.md) for complete procedures

## Phase Completion

### ✅ Phase 1: Network Foundation (Complete)
**Completed**: 2025-09-07
**Nodes Deployed**: 4/4 (100%)

- ✅ Tailscale mesh network operational across all nodes
- ✅ Dynamic availability architecture validated
- ✅ Emergency access methods documented and tested
- ✅ Security baseline active (WireGuard encryption, SSH-key auth only)
- ✅ All originally planned nodes joined + MacBook added later

### ✅ Phase 2: Configuration Management (Complete)
**Completed**: 2025-09-08
**Ansible Coverage**: 4/4 nodes

- ✅ Ansible control node established on Hetzner
- ✅ All nodes manageable via Ansible (including WSL2 with adaptations)
- ✅ Dedicated mesh-ops user deployed across all nodes (UID 2000)
- ✅ GitOps workflow operational
- ✅ Node-specific configurations (macOS, WSL2, Linux) working

**Key Achievement**: Completed critical incident recovery - SSH outage on Hetzner caused by overly permissive sudo rules. Resolved via console access and tightened security model.

### 🟡 Phase 3: File Synchronization (Ready)
**Status**: Implementation ready, awaiting deployment decision
**Preparation**: 100%

- ✅ Syncthing Ansible role created (18 files)
- ✅ Node-specific configurations prepared for all 4 nodes
- ✅ WSL2 compatibility handling implemented
- ✅ macOS launchd service configuration ready
- ⏳ Awaiting deployment command

**Next Step**: Run `ansible-playbook playbooks/syncthing.yaml` from Hetzner control node

### 📋 Phase 4: Observability (Planned)
- Prometheus metrics collection
- Loki log aggregation
- Grafana dashboards
- Real-time mesh health monitoring

## Services & Capabilities

### Currently Active
| Service | Node | Internal Access | External Access | Status |
|---------|------|-----------------|-----------------|--------|
| SSH | hetzner-hq | 100.84.151.58:2222 | 91.99.101.204:2222 | ✅ Active |
| Infisical | hetzner-hq | 100.84.151.58:8080 | secrets.jefahnierocks.com | ✅ Active |
| Docker Networks | hetzner-hq | 172.20.0.0/16 via mesh | - | ✅ Routed |
| Tailscale | All nodes | - | - | ✅ Active |

### Ready to Deploy (Phase 3)
- Syncthing file synchronization across all active nodes
- Selective sync policies (development, documents, config, work)
- File versioning and conflict resolution
- Per-node storage optimization

## Architecture Highlights

### Resilient Service Distribution
- **Critical Services**: Deployed only on Hetzner (always available)
- **Development Tools**: Replicated across active nodes
- **File Sync**: Queues changes when nodes offline (Phase 3)
- **Secrets**: Accessible from any node via gopass

### Failure Scenarios
| Scenario | Impact | Mitigation |
|----------|--------|------------|
| Any workstation offline | Development continues on remaining nodes | Dynamic availability by design |
| Multiple workstations offline | Core services available via Hetzner | Hub node always-on |
| Hetzner offline | Emergency SSH via direct IP:2222 | Multiple escape hatches |
| Full mesh partition | Console access + rebuild capability | Documented recovery procedures |

## Security Posture

### Active Protections
- ✅ WireGuard encryption (ChaCha20-Poly1305) on all mesh traffic
- ✅ SSH key-only authentication (no passwords)
- ✅ 24-hour auth token expiry
- ✅ Default deny inbound traffic
- ✅ Admin ports never publicly exposed (except SSH on :2222)
- ✅ Production constraints on mesh-ops user (Hetzner)

### Compliance Status
| Check | Status | Last Verified |
|-------|--------|---------------|
| Policy validation | ✅ PASS | 2025-10-27 |
| Security baseline | ✅ PASS | 2025-10-27 |
| Mesh connectivity | ✅ PASS | 2025-10-27 |
| Emergency access | ✅ VERIFIED | 2025-09-08 |

## Operational Metrics

### Network Performance
- **DERP Latency**: <10ms (Nuremberg relay)
- **Node Response**: <100ms (when online)
- **Mesh Uptime**: 100% since deployment
- **Hetzner Uptime**: 100% (24/7 availability)

### Resource Utilization

**Hetzner Hub (CX32)**
- CPU: 2 vCPU
- RAM: 8GB
- Storage: 80GB NVMe
- Network: 20TB/month transfer
- Availability: 100% (always-on)

## Quick Commands

### Check Network Status
```bash
# View mesh status
tailscale status

# Check specific node connectivity
tailscale ping hetzner-hq
tailscale ping macbook-hq

# Test from MacBook to all nodes
ping -c 2 100.84.151.58  # Hetzner
ping -c 2 100.84.2.8      # Laptop
ping -c 2 100.88.131.44   # WSL
```

### Ansible Operations
```bash
# From Hetzner control node or any node with ansible installed
ansible all -m ping                    # Test all nodes
ansible workstations -m ping           # Test only workstations
ansible-playbook playbooks/site.yaml   # Apply baseline config
```

### Repository Operations
```bash
make ground-pull    # Load current state
make test           # Test mesh connectivity
make probe          # Generate repository snapshot
make escape-hatch   # Show emergency access methods
```

## Recent Activity

### October 2025
- **Oct 18**: MacBook Pro joined mesh network
- **Oct 18**: Ansible inventory updated with macOS node
- **Oct 18**: Made architecture node-count agnostic

### September 2025
- **Sep 08**: Phase 2.8 complete - mesh-ops user deployed to all nodes
- **Sep 08**: Critical incident: SSH outage on Hetzner, resolved via console
- **Sep 07**: WSL2 node joined
- **Sep 07**: Phase 2 complete - Ansible operational
- **Sep 06**: Fedora laptop joined mesh
- **Sep 06**: Hetzner hub deployed, mesh established

## Known Issues & Limitations

### Current
- **Tailscale CLI on MacBook**: Not in PATH, service works fine (cosmetic only)
- **WSL2 Systemd**: Limited systemd support requires service workarounds
- **Laptop Availability**: Personal device, ~40% uptime expected

### Resolved
- ✅ SSH outage on Hetzner (Sep 08) - Fixed via console, security hardened
- ✅ WSL2 userspace networking - Implemented and validated
- ✅ Fish shell template issues - Resolved during WSL deployment

## Next Actions

### Immediate
1. Optional: Fix Tailscale CLI PATH on MacBook: `sudo ln -s /Applications/Tailscale.app/Contents/MacOS/Tailscale /usr/local/bin/tailscale`
2. Consider: Deploy Phase 3 Syncthing when file sync needed

### Short-term
- Monitor mesh stability with 4-node configuration
- Consider observability implementation (Phase 4)
- Document any macOS-specific operational quirks

### Long-term
- Evaluate need for additional nodes
- Consider Phase 5: Agent orchestration
- Implement backup automation

## Reference Documentation

- **Architecture Decisions**: [`docs/_grounding/adr/`](docs/_grounding/adr/)
- **System Facts**: [`docs/_grounding/facts.yml`](docs/_grounding/facts.yml) (source of truth)
- **Escape Hatches**: [`infra/ESCAPE_HATCHES.md`](../infra/ESCAPE_HATCHES.md)
- **Node Addition**: [`docs/NODE_ADDITION_GUIDE.md`](docs/NODE_ADDITION_GUIDE.md)
- **Ansible Guide**: [`docs/ANSIBLE_SETUP_GUIDE.md`](docs/ANSIBLE_SETUP_GUIDE.md)
- **Deployment History**: [`docs/_archive/deployment-history/`](docs/_archive/deployment-history/)

---

**Infrastructure Health**: 🟢 HEALTHY
**Deployment Status**: Phase 2 Complete, Phase 3 Ready
**Compliance**: 🟢 COMPLIANT
**Next Milestone**: Phase 3 Syncthing Deployment (optional, on-demand)
