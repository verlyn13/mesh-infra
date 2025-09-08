.PHONY: help ground-pull ground-plan probe init-day1 escape-hatch test lint doc-check policy-check policy-generate ansible-setup ansible-ping ansible-site ansible-install-tools syncthing-deploy syncthing-status mesh-user-create mesh-user-create-wsl mesh-user-validate mesh-user-bootstrap mesh-user-deploy-all mesh-user-ssh-keys mesh-user-switch

help:
	@echo "=== Mesh Infrastructure Management ==="
	@echo ""
	@echo "Core Operations:"
	@echo "  make init-day1       - Initialize Day 1 infrastructure"
	@echo "  make ground-pull     - Sync repository state (for agents)"
	@echo "  make ground-plan     - Create new session plan"
	@echo "  make probe           - Generate repository snapshot"
	@echo "  make escape-hatch    - Show emergency access methods"
	@echo "  make test            - Test mesh connectivity"
	@echo "  make lint            - Lint Python and shell scripts"
	@echo ""
	@echo "Mesh-Ops User Management:"
	@echo "  make mesh-user-create      - Create mesh-ops user on local node"
	@echo "  make mesh-user-create-wsl  - Create mesh-ops user for WSL2"
	@echo "  make mesh-user-validate    - Validate mesh-ops user setup"
	@echo "  make mesh-user-bootstrap   - Install development tools for mesh-ops"
	@echo "  make mesh-user-ssh-keys    - Generate/show SSH keys for mesh-ops"
	@echo "  make mesh-user-switch      - Switch to mesh-ops user"
	@echo ""
	@echo "Configuration Management:"
	@echo "  make ansible-setup         - Run Ansible setup on control node"
	@echo "  make ansible-ping          - Ping all hosts via Ansible"
	@echo "  make ansible-site          - Apply site playbook"
	@echo "  make ansible-install-tools - Install dev tools everywhere"
	@echo ""
	@echo "Services:"
	@echo "  make syncthing-deploy      - Deploy Syncthing file sync"
	@echo "  make syncthing-status      - Check Syncthing status"
	@echo ""
	@echo "Documentation & Policy:"
	@echo "  make doc-check             - Validate docs structure"
	@echo "  make policy-check          - Validate policy intent"
	@echo "  make policy-generate       - Generate vendor configs"

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

# --- Phase 3: Syncthing File Sync ---
syncthing-deploy:
	@cd ansible && ansible-playbook playbooks/syncthing.yaml

syncthing-status:
	@cd ansible && ansible all -m shell -a 'systemctl --user status syncthing || systemctl status syncthing@verlyn13'

# --- Phase 2: Mesh-Ops User Management ---
mesh-user-create: ## Create mesh-ops user on local node
	@echo "Creating mesh-ops user on $$(hostname)..."
	@NODE_TYPE=$$(hostname -s | grep -q "wsl" && echo "wsl" || (hostname -s | grep -q "hetzner" && echo "hub" || echo "standard")); \
	bash scripts/create-mesh-user.sh $$NODE_TYPE

mesh-user-create-wsl: ## Create mesh-ops user for WSL2 environment
	@echo "Running WSL2-specific mesh-ops setup..."
	@bash scripts/setup-mesh-user-wsl.sh

mesh-user-validate: ## Validate mesh-ops user setup
	@echo "Validating mesh-ops user configuration..."
	@bash scripts/validate-mesh-ops.sh

mesh-user-bootstrap: ## Bootstrap mesh-ops user with development tools
	@echo "Bootstrapping mesh-ops user environment..."
	@cd ansible && ansible-playbook -i inventory/hosts.ini playbooks/bootstrap-mesh-ops.yml

mesh-user-deploy-all: ## Deploy mesh-ops user to all nodes via Ansible
	@echo "Deploying mesh-ops user to all mesh nodes..."
	@echo "Note: Create deployment playbook first with: ansible/playbooks/deploy-mesh-ops-user.yml"
	@cd ansible && ansible-playbook -i inventory/hosts.ini playbooks/deploy-mesh-ops-user.yml || echo "Playbook not yet created"

mesh-user-ssh-keys: ## Exchange SSH keys between mesh-ops users
	@echo "Setting up SSH key exchange for mesh-ops users..."
	@sudo -u mesh-ops ssh-keygen -t ed25519 -f /home/mesh-ops/.ssh/id_ed25519 -N "" -C "mesh-ops@$$(hostname)" 2>/dev/null || true
	@echo "Public key for this node:"
	@sudo -u mesh-ops cat /home/mesh-ops/.ssh/id_ed25519.pub 2>/dev/null || echo "mesh-ops user not created yet"

mesh-user-switch: ## Switch to mesh-ops user
	@echo "Switching to mesh-ops user..."
	@sudo su - mesh-ops
