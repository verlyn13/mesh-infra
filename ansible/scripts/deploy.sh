#!/usr/bin/env bash
# Helper to run Ansible playbooks with sensible defaults
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
ROOT_DIR="${SCRIPT_DIR}/.."

PLAYBOOK=${1:-playbooks/site.yaml}
LIMIT=${2:-}
TAGS=${3:-}

cd "$ROOT_DIR"

echo "Using inventory: $(realpath inventory/hosts.yaml)"
echo "Running playbook: $PLAYBOOK"

EXTRA_ARGS=()
if [[ -n "$LIMIT" ]]; then
  EXTRA_ARGS+=(--limit "$LIMIT")
fi
if [[ -n "$TAGS" ]]; then
  EXTRA_ARGS+=(--tags "$TAGS")
fi

ansible-playbook "$PLAYBOOK" "${EXTRA_ARGS[@]}"

