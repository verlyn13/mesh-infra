# Agent Session Template

## Before Starting
1. Run: `make ground-pull` to sync latest state
2. Read: docs/_grounding/facts.yml
3. Check: git status and current branch

## Session Contract
```yaml
session_id: [auto-generated]
started_at: [timestamp]
agent: [claude-code|windsurf|codex]
commit: [git-hash]
scope:
  include: []  # paths agent can modify
  exclude: [docs/_grounding/*, infra/policy/intent/*]  # never touch
goals:
  - [specific deliverable]
constraints:
  - Do not modify grounding files
  - All changes must have tests
  - Update docs/_generated/snapshot.json before commit
```

## Required Checks Before PR
- [ ] Session file created in .session/
- [ ] facts.yml unchanged
- [ ] Tests added/updated
- [ ] Snapshot regenerated
- [ ] No scope violations