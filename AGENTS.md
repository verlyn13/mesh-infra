# Repository Guidelines

## Project Structure & Modules
- `infra/`: Infrastructure scripts and policy.
  - `scripts/`: bootstrap, day‑1 setup, mesh tests.
  - `policy/intent/`: vendor‑neutral intent (`network.yaml`) and generator.
  - `backup/`: WireGuard emergency assets (do not commit secrets).
- `scripts/`: Python utilities (`ground.py`, `repo_probe.py`).
- `docs/_grounding/`: Knowledge for agents — do not modify.
- `docs/_generated/`: Derived artifacts (e.g., `snapshot.json`).
- `.session/`: Session plans created by agents/tools.
- `Makefile`: Primary entry points.

## Build, Test, and Dev Commands
- `make help`: List available tasks.
- `make ground-pull`: Show current facts and git status.
- `make ground-plan`: Create a new agent session file in `.session/`.
- `make probe`: Regenerate repository snapshot under `docs/_generated/`.
- `make init-day1`: Day‑1 mesh bootstrap (node‑aware).
- `make test`: Mesh connectivity smoke tests.
- `python3 scripts/ground.py commit`: Validate before committing (checks grounding, refreshes snapshot).

## Coding Style & Naming
- Python: 4‑space indent, type hints, descriptive names; run `ruff` locally.
- Bash: `set -euo pipefail`, lower_snake_case functions; run `shellcheck`.
- Files: group imports alphabetically; keep functions small and purpose‑named.
- Generated outputs live in `docs/_generated/` and `infra/policy/generated/`—do not hand‑edit.

## Testing Guidelines
- Unit tests for Python helpers (e.g., parse/scan functions). Suggested: `pytest`.
- Integration: `make probe` and `make test` before PRs.
- Aim for >80% coverage on new Python modules; mock external commands.
- Name tests `test_*.py` and mirror directory of code under test.

## Commit & PR Workflow
- Branch: `feat/<scope>`, `fix/<scope>`, or `chore/<scope>`.
- Commits: Conventional style (e.g., `feat(ground): add commit check`).
- PRs: clear description, linked issues, command outputs/screenshots for `make probe`/`make test`.
- Before pushing: `make ground-pull` → update docs if needed → `python3 scripts/ground.py commit`.

## Security & Configuration
- Never commit secrets; keep real keys in secure stores. Backup artifacts under `infra/backup/` must remain local.
- Do not modify `docs/_grounding/*`.
- Treat `infra/policy/intent/network.yaml` as the source of truth; generate configs with `infra/policy/intent/generate.sh`.
