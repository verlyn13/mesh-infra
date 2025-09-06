# Three-Node (for now) Mesh Infrastructure

A personal platform-as-code infrastructure connecting a Hetzner cloud server, Fedora laptop, and WSL2 development environment through a secure mesh network, designed for seamless development workflows and AI-assisted operations.

## 🎯 Project Purpose

This project creates a unified, always-accessible personal computing environment across three distinct systems:

- **Hetzner Cloud Server** (Ubuntu 24.04) - Always-on hub in Germany
- **Fedora Laptop** (ThinkPad) - Roaming primary workstation  
- **Fedora WSL2** - Windows-constrained work environment

### Why This Exists

Modern development happens across multiple machines, networks, and contexts. This infrastructure solves:

1. **Seamless Access**: Work from anywhere (college wifi, coffee shops, home) without VPN configuration headaches
2. **Unified Environment**: Same tools, files, and services accessible from any node
3. **AI-Resistant Structure**: Built to work with AI coding assistants (Claude Code, Windsurf, Copilot) without drift or confusion
4. **Resource Sharing**: Leverage Hetzner's always-on compute for builds, services, and storage
5. **Escape Hatches**: Multiple fallback access methods when primary systems fail

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   Internet / Public Networks            │
└─────────────────────────────────────────────────────────┘
                            │
                            │ 91.99.101.204
                            ▼
                ┌──────────────────────┐
                │   Hetzner Server     │
                │   (docker-cx32-prod) │
                │   Always-On Hub      │
                │   - Services         │
                │   - Storage          │
                │   - Coordination     │
                └──────────────────────┘
                            │
                 ┌──────────┴──────────┐
                 │  Mesh Network       │
                 │  (10.0.0.0/24)      │
                 │  Tailscale/WG       │
                 └──────────┬──────────┘
                            │
            ┌───────────────┴───────────────┐
            │                               │
    ┌──────────────────┐           ┌──────────────────┐
    │  Fedora Laptop   │           │   Fedora WSL2    │
    │  (fedora-top)    │           │  (fedora-wsl)    │
    │  Roaming Device  │           │  KBC-JJOHNSON47  │
    │  10.0.0.2        │           │  10.0.0.3        │
    └──────────────────┘           └──────────────────┘
```

### Network Design

- **Primary Mesh**: Tailscale for zero-config NAT traversal
- **Fallback**: WireGuard with manual configuration
- **Emergency Access**: Direct SSH on port 2222 to Hetzner
- **Internal Domain**: `*.hq` for all mesh services

## 🚀 Key Features

### For Developers

- **Unified SSH Access**: `ssh laptop.hq` works from anywhere
- **Persistent Services**: Databases, APIs, and tools on Hetzner
- **Synchronized Files**: Code and configs available on all nodes
- **Remote Development**: VSCode/Neovim remote sessions
- **Distributed Builds**: Offload heavy compilation to Hetzner

### For AI-Assisted Development

- **Grounding Bundle**: Single source of truth in `/docs/_grounding/`
- **Session Contracts**: Each AI session gets scoped access
- **Policy as Code**: Automated enforcement of best practices
- **Drift Prevention**: Immutable facts file, protected paths
- **Clear Boundaries**: What AI agents can and cannot modify

### For Operations

- **GitOps Workflow**: Git as desired state, reality as actual state
- **Multiple Escape Hatches**: Never locked out of infrastructure
- **Security First**: Zero-trust, certificate-based authentication
- **Audit Trails**: All changes tracked and attributable
- **Progressive Enhancement**: Start simple, add complexity as needed

## 📁 Repository Structure

```
mesh-infra/
├── docs/
│   ├── _grounding/        # Source of truth (AI agents: READ ONLY)
│   │   ├── facts.yml      # Immutable system facts
│   │   ├── module_map.json # Code ownership
│   │   ├── roadmap.md     # Project phases
│   │   └── adr/           # Architecture decisions
│   └── _generated/        # Machine-generated state
│       └── snapshot.json  # Current repo state
├── infra/
│   ├── policy/           
│   │   └── intent/        # Vendor-neutral policies
│   ├── bootstrap/         # Node joining procedures
│   ├── backup/            # Emergency configs
│   └── scripts/           # Automation tooling
├── .session/              # AI agent session tracking
└── Makefile               # Common operations
```

## 🎬 Getting Started

### Prerequisites

- SSH access to all three nodes
- sudo/admin rights on Linux systems (not required on Windows host)
- Basic familiarity with terminal operations

### Day 1: Establish the Mesh

```bash
# 1. Clone this repository on Hetzner
git clone https://github.com/verlyn13/mesh-infra
cd mesh-infra

# 2. Initialize the hub node
make init-day1

# 3. Verify Tailscale is running
tailscale status

# 4. Repeat on laptop and WSL nodes
# Then test connectivity
for node in hetzner.hq laptop.hq wsl.hq; do 
    ping -c 1 $node && echo "✓ $node connected"
done
```

### For AI Assistants

When using Claude Code, Windsurf, or other AI coding assistants:

```bash
# Before starting any work
make ground-pull  # Load current state
make ground-plan  # Create session plan

# After making changes
make probe        # Update snapshot
make test         # Verify connectivity
```

## 🔐 Security Model

- **Authentication**: SSH keys only, no passwords
- **Authorization**: Time-boxed tokens (24hr expiry)
- **Network**: Default deny, explicit allow rules
- **Secrets**: Managed via gopass/Infisical
- **Audit**: All operations logged to Hetzner

## 🗺️ Roadmap

### ✅ Phase 1: Network Foundation (Current)
- Mesh VPN connectivity
- Emergency access methods
- Basic security policies

### 📋 Phase 2: Configuration Management
- Ansible playbooks
- Automated updates
- Service deployment

### 📋 Phase 3: File Synchronization
- Syncthing setup
- Selective sync rules
- Backup strategies

### 📋 Phase 4: Observability
- Prometheus metrics
- Loki log aggregation
- Grafana dashboards

### 📋 Phase 5: Agent Orchestration
- Service discovery
- Job scheduling
- Resource allocation

## 🛠️ Common Operations

```bash
make help           # Show all commands
make probe          # Generate repository snapshot
make escape-hatch   # Show emergency access methods
make test           # Test mesh connectivity
```

## 🚨 Emergency Access

If the mesh network fails:

1. **Direct SSH**: `ssh verlyn13@91.99.101.204 -p 2222`
2. **WireGuard Fallback**: `wg-quick up infra/backup/wg/emergency.conf`
3. **Console Access**: Hetzner Cloud web console

## 📚 Documentation

- [Day 1 Setup](docs/_grounding/Day1.md) - Initial bootstrap procedures
- [Network Reference](docs/_grounding/network-reference.yaml) - System specifications
- [Escape Hatches](infra/ESCAPE_HATCHES.md) - Emergency procedures
- [Architecture Decisions](docs/_grounding/adr/) - Design rationale

## 🤝 Contributing

This is a personal infrastructure project, but ideas and suggestions are welcome:

1. **For AI Agents**: Always use `make ground-plan` before starting
2. **For Humans**: Create an ADR for significant changes
3. **For Everyone**: Never modify files in `docs/_grounding/` directly

## 📄 License

MIT - This is personal infrastructure code shared for educational purposes.

## 🙏 Acknowledgments

- Built with assistance from Claude (Anthropic)
- Inspired by platform engineering best practices
- Leveraging Tailscale's excellent mesh networking
- Standing on the shoulders of countless open source projects

---

**Project Status**: 🟢 Active Development (Day 1 Phase)  
**Primary Contact**: verlyn13  
**Last Updated**: 2025-09-05
```

This README:
- Explains the "why" behind the project clearly
- Shows the technical architecture visually
- Provides concrete getting-started steps
- Acknowledges the AI-assisted workflow
- Sets expectations for different types of users
- Includes emergency procedures upfront
- Maps out the future roadmap
- Maintains a professional but personal tone

Feel free to adjust the tone, add more technical details, or emphasize different aspects based on your preferences!
