.PHONY: help ground-pull ground-plan probe init-day1 escape-hatch test lint doc-check policy-check policy-generate ansible-setup ansible-ping ansible-site ansible-install-tools

help:
	@echo "Mesh Infrastructure Management"
	@echo "  make init-day1    - Initialize Day 1 infrastructure"
	@echo "  make ground-pull  - Sync repository state (for agents)"
	@echo "  make ground-plan  - Create new session plan"
	@echo "  make probe        - Generate repository snapshot"
	@echo "  make escape-hatch - Show emergency access methods"
	@echo "  make lint         - Lint Python and shell scripts"
	@echo "  make doc-check    - Validate docs structure and links"
	@echo "  make policy-check - Validate policy intent and generator"
	@echo "  make policy-generate - Generate vendor-specific configs"
	@echo "  make ansible-setup   - Run Ansible setup on control node"
	@echo "  make ansible-ping    - Ping all hosts via Ansible"
	@echo "  make ansible-site    - Apply site playbook"
	@echo "  make ansible-install-tools - Install dev tools everywhere"

ground-pull:
	@python3 scripts/ground.py pull

ground-plan:
	@python3 scripts/ground.py plan

probe:
	@python3 scripts/repo_probe.py

init-day1:
	@echo "Starting Day 1 initialization..."
	@bash infra/scripts/init-day1.sh

escape-hatch:
	@echo "=== EMERGENCY ACCESS ==="
	@echo "1. Direct SSH: ssh verlyn13@91.99.101.204 -p 2222"
	@echo "2. WireGuard: wg-quick up infra/backup/wg/emergency.conf"
	@echo "3. Console: Hetzner web console"

test:
	@echo "Testing mesh connectivity..."
	@bash infra/scripts/test-mesh.sh

lint:
	@echo "Linting Python (ruff) and shell (shellcheck)..."
	@ruff check scripts || true
	@find infra/scripts -type f -name "*.sh" -print0 | xargs -0 -r shellcheck || true

doc-check:
	@python3 scripts/doc_check.py

policy-check:
	@python3 scripts/policy_check.py

policy-generate:
	@bash infra/policy/intent/generate.sh

# --- Ansible helpers ---
ansible-setup:
	@cd ansible && ./scripts/setup.sh

ansible-ping:
	@cd ansible && ansible all -m ping

ansible-site:
	@cd ansible && ansible-playbook playbooks/site.yaml

ansible-install-tools:
	@cd ansible && ansible-playbook playbooks/install-tools.yaml
