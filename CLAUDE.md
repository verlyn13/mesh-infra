# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Three-node mesh infrastructure connecting Hetzner cloud server, Fedora laptop, and WSL2 dev environment through Tailscale. This is a platform-as-code personal infrastructure project for seamless development workflows.

## Essential Commands

### Development Workflow
```bash
make ground-pull    # Load current state before starting work
make ground-plan    # Create session plan for AI agents
make probe          # Generate repository snapshot after changes
make test           # Test mesh connectivity
make lint           # Run ruff (Python) and shellcheck (shell scripts)
```

### Infrastructure Management
```bash
make init-day1      # Initialize Day 1 infrastructure
make escape-hatch   # Show emergency access methods
make policy-check   # Validate policy intent files
make policy-generate # Generate vendor-specific configs from intent
make doc-check      # Validate documentation structure
```

### Testing
```bash
# Run all tests
for test in tests/*.sh; do bash "$test"; done

# Specific tests
bash tests/verify_foundation.sh  # Check repository structure
bash tests/test_workflows.sh     # Test workflows and protection
```

## Architecture & Key Components

### Network Architecture
- **Mesh Network**: Tailscale (100.64.0.0/10 CGNAT space)
- **Hub Node**: Hetzner server (100.84.151.58) - always-on exit node
- **Nodes**: 
  - Hetzner (hetzner-hq): 91.99.101.204:2222, 100.84.151.58
  - Laptop (laptop-hq): 100.84.2.8 (roaming)
  - WSL2 (wsl-hq): Pending deployment

### Directory Structure
```
mesh-infra/
├── ansible/         # Ansible playbooks and inventory (Phase 2)
├── docs/
│   └── _grounding/  # Source of truth - READ ONLY, contains facts.yml
├── infra/
│   ├── policy/      # Policy as code definitions
│   └── scripts/     # Infrastructure automation scripts
├── scripts/         # Python utilities (ground.py, repo_probe.py, etc.)
└── tests/           # Shell test scripts
```

### Key Files
- `docs/_grounding/facts.yml` - Immutable system facts (IPs, hostnames, network config)
- `Makefile` - All common operations and commands
- `.claude-instructions` - AI assistant guidelines

## Critical Rules

### NEVER Modify
- `docs/_grounding/facts.yml` - Source of truth for system facts
- `infra/policy/intent/*.yaml` - Policy intent files
- `CODEOWNERS` - Code ownership definitions

### ALWAYS Do
- Run `make ground-pull` before starting any work
- Update tests when changing code
- Run `make probe` before commits
- Check git branch before starting work

## Python Code Standards
- Use `ruff` for linting (configured in project)
- Follow existing patterns in `scripts/` directory
- All scripts should be executable with proper shebang

## Shell Script Standards
- Use `shellcheck` for validation
- Scripts in `infra/scripts/` and test scripts in `tests/`
- Prefer bash over sh for consistency

## Current Phase
**Phase 1**: Network Foundation (66% complete)
- 2/3 nodes deployed (Hetzner and Laptop online, WSL pending)
- Emergency access methods documented
- Basic security policies active

**Next**: Phase 2 - Configuration Management with Ansible