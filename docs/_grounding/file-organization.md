# File Organization Policy

## Directory Structure

```
mesh-infra/
├── docs/                    # All documentation
│   ├── _grounding/         # Protected source of truth
│   │   ├── adr/           # Architecture decisions
│   │   └── sessions/      # Agent session records
│   └── _generated/        # Machine-generated docs
├── infra/                  # Infrastructure code
│   ├── policy/            # Network and security policies
│   │   ├── intent/       # Vendor-neutral definitions
│   │   └── generated/    # Vendor-specific configs
│   ├── bootstrap/         # Node initialization
│   ├── backup/           # Emergency configs
│   │   └── wg/          # WireGuard fallback
│   └── scripts/          # Infrastructure automation
├── scripts/               # Repository tooling
│   ├── ground.py         # Agent interface
│   ├── repo_probe.py     # State tracking
│   ├── doc_check.py      # Documentation validation
│   └── policy_check.py   # Policy validation
├── tests/                 # All test scripts
│   ├── verify_foundation.sh
│   └── test_workflows.sh
├── .session/              # Agent work tracking
└── .claude/               # Claude-specific config
```

## File Placement Rules

1. **Root Directory**: Only essential files
   - README.md - Project overview
   - Makefile - Primary operations
   - CODEOWNERS - GitHub protection
   - .gitignore - Git configuration
   - AGENTS.md - AI agent instructions
   - Configuration files (.clinerules-*, .claude-instructions)

2. **Scripts Directory (`scripts/`)**: Repository management tools
   - Python scripts for repository operations
   - Agent interface tools
   - Validation and checking tools
   - NOT for infrastructure scripts

3. **Infrastructure Scripts (`infra/scripts/`)**: System configuration
   - Node initialization scripts
   - Network configuration
   - Service deployment
   - Emergency procedures

4. **Tests Directory (`tests/`)**: All test scripts
   - Integration tests
   - Verification scripts
   - Workflow tests
   - Performance tests

5. **Documentation (`docs/`)**: All documentation
   - Grounding files (protected)
   - Generated reports
   - Session records
   - Architecture decisions

## Naming Conventions

- Shell scripts: `kebab-case.sh`
- Python scripts: `snake_case.py`
- Documentation: `kebab-case.md`
- Config files: `dot-prefixed`
- Directories: `lowercase`

## Protected Paths

These paths must NEVER be modified by agents:
- `/docs/_grounding/facts.yml`
- `/docs/_grounding/module_map.json`
- `/infra/policy/intent/*.yaml`
- `/CODEOWNERS`

## Script Categories

### Repository Management (`scripts/`)
- ground.py - Agent session management
- repo_probe.py - State snapshots
- doc_check.py - Documentation validation
- policy_check.py - Policy validation

### Infrastructure (`infra/scripts/`)
- init-day1.sh - Node bootstrap
- test-mesh.sh - Network testing
- backup-keys.sh - Key management
- emergency-restore.sh - Disaster recovery

### Testing (`tests/`)
- verify_foundation.sh - Structure validation
- test_workflows.sh - Process testing
- integration_test.sh - End-to-end tests

## File Creation Guidelines

When creating new files:
1. Check this policy first
2. Place in appropriate directory
3. Follow naming conventions
4. Update module_map.json if adding new module
5. Add to .gitignore if contains secrets
6. Document in relevant README