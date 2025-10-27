# Documentation Index

**Mesh Infrastructure Documentation** - Complete navigation guide

Last Updated: 2025-10-27

## 🚀 Quick Start

New to the project? Start here:

1. **[Main README](../README.md)** - Project overview and purpose
2. **[Infrastructure Status](STATUS.md)** - Current system health (⭐ **START HERE** for current state)
3. **[Day 1 Setup](docs/_grounding/Day1.md)** - Initial deployment procedures

## 📊 Current Status & Operations

**Live Documentation** (Always up-to-date)

- **[Infrastructure Status](STATUS.md)** - Single source of truth for current system state
  - Node availability and health
  - Network configuration
  - Phase completion status
  - Recent activity and metrics

**Operational Guides**

- [Ansible Setup Guide](ANSIBLE_SETUP_GUIDE.md) - Configuration management workflows
- [Node Addition Guide](NODE_ADDITION_GUIDE.md) - How to add new nodes to the mesh
- [Mesh Ops Management](MESH_OPS_MANAGEMENT.md) - Dedicated user management
- [Security Safeguards](SECURITY_SAFEGUARDS.md) - Security policies and practices
- [Escape Hatches](../infra/ESCAPE_HATCHES.md) - Emergency access procedures

## 🏗️ Architecture & Design

**Source of Truth** (Read-only, immutable facts)

- [System Facts](docs/_grounding/facts.yml) - Immutable system facts (IPs, hostnames, config)
- [Architecture Decisions](docs/_grounding/adr/) - Design rationale and ADRs
  - [ADR 0001: Vendor-Neutral Intent](docs/_grounding/adr/0001-vendor-neutral-intent.md)
- [File Organization](docs/_grounding/file-organization.md) - Repository structure
- [Roadmap](docs/_grounding/roadmap.md) - Project phases and milestones

## 🔧 Implementation Guides

**Phase 3: File Synchronization** (Ready to deploy)

- [Phase 3 Readiness](PHASE3_READINESS.md) - Deployment readiness assessment
- [Phase 3 Implementation](PHASE3_IMPLEMENTATION.md) - Technical implementation details
- [Phase 3 Deployment Guide](PHASE3_DEPLOYMENT_GUIDE.md) - Step-by-step deployment

**Historical Phase Documentation**

- [Phase 2 Plan](PHASE2_PLAN.md) - Configuration management planning (completed)
- [Incident Report: SSH Outage](INCIDENT_REPORT_SSH_OUTAGE.md) - Critical incident recovery

## 📚 Reference Materials

**System Specifications**

- [Components Inventory](COMPONENTS_INVENTORY.yaml) - Hardware and software inventory
- Network Reference: See [facts.yml](docs/_grounding/facts.yml) for authoritative network config

**Generated Documentation** (Auto-updated by `make probe`)

- [Repository Snapshot](docs/_generated/snapshot.json) - Current repository state
- [Deployment Status](docs/_generated/deployment_status.json) - Machine-readable status

## 📁 Historical Archive

**Deployment History** (Point-in-time reports)

Located in [`_archive/deployment-history/`](_archive/deployment-history/):

- [Day 1 Report](_archive/deployment-history/DAY1_REPORT.md) - Initial hub deployment (Sep 7, 2025)
- [Laptop Join Report](_archive/deployment-history/LAPTOP_JOIN_REPORT.md) - Fedora laptop (Sep 6, 2025)
- [MacBook Join Report](_archive/deployment-history/MACBOOK_JOIN_REPORT.md) - MacBook Pro (Oct 18, 2025)
- [MacBook SSH Setup](_archive/deployment-history/MACBOOK_SSH_SETUP_GUIDE.md) - macOS configuration

**Planning Archives**

Located in [`_archive/planning/`](_archive/planning/):

- [Phase 2.8 Plan](_archive/planning/PHASE2-8_PLAN.md) - Mesh-ops user deployment planning
- [Infrastructure Status Report](_archive/planning/INFRASTRUCTURE_STATUS_REPORT.md) - Historical status (Sep 7)
- [Deployment Status](_archive/planning/DEPLOYMENT_STATUS.md) - Phase 2.8 completion report

## 🔍 Documentation by Use Case

### I want to...

**...understand the current system state**
→ [Infrastructure Status](STATUS.md)

**...add a new node to the mesh**
→ [Node Addition Guide](NODE_ADDITION_GUIDE.md)

**...deploy configuration changes**
→ [Ansible Setup Guide](ANSIBLE_SETUP_GUIDE.md)

**...deploy file synchronization**
→ [Phase 3 Deployment Guide](PHASE3_DEPLOYMENT_GUIDE.md)

**...recover from emergency**
→ [Escape Hatches](../infra/ESCAPE_HATCHES.md)

**...understand a design decision**
→ [Architecture Decisions](docs/_grounding/adr/)

**...see deployment history**
→ [Historical Archive](_archive/deployment-history/)

**...work with AI coding assistants**
→ [CLAUDE.md](../CLAUDE.md) and [AGENTS.md](../AGENTS.md)

## 🎯 Documentation Principles

This documentation follows these principles:

1. **Single Source of Truth**: [STATUS.md](STATUS.md) is authoritative for current state
2. **Immutable Facts**: [facts.yml](docs/_grounding/facts.yml) never edited directly, only updated through validated processes
3. **Historical Preservation**: Point-in-time reports archived, not deleted
4. **Cross-referencing**: Related docs link to each other
5. **Value Density**: Every document serves a clear purpose
6. **AI-Friendly**: Structured for both human and AI consumption

## 📝 Contributing to Documentation

When updating documentation:

1. **Status changes**: Update [STATUS.md](STATUS.md)
2. **New nodes**: Update [facts.yml](docs/_grounding/facts.yml) and run `make probe`
3. **Design decisions**: Create ADR in [docs/_grounding/adr/](docs/_grounding/adr/)
4. **Completed deployments**: Move planning docs to [_archive/planning/](_archive/planning/)
5. **Cross-reference**: Link related documents together

## 🛠️ Documentation Tools

```bash
# Update generated documentation
make probe

# Validate documentation structure
make doc-check

# Load current state before work
make ground-pull

# Create AI session plan
make ground-plan
```

---

**Quick Links**: [Main README](../README.md) | [Status](STATUS.md) | [Ansible Guide](ANSIBLE_SETUP_GUIDE.md) | [Node Addition](NODE_ADDITION_GUIDE.md)

**For AI Assistants**: See [CLAUDE.md](../CLAUDE.md) for project-specific guidance
