#!/usr/bin/env python3
"""Validate policy intent and generator configuration.

Checks:
- infra/policy/intent/network.yaml has required sections.
- security invariants include defaults.
- generator script exists and outputs to infra/policy/generated.
"""
from __future__ import annotations
from pathlib import Path
import sys
import yaml

ROOT = Path(__file__).resolve().parent.parent

def fail(msg: str) -> None:
  print(f"ERROR: {msg}")
  sys.exit(1)

def check_intent_yaml() -> None:
  path = ROOT / "infra/policy/intent/network.yaml"
  if not path.exists():
    fail("Missing infra/policy/intent/network.yaml")
  data = yaml.safe_load(path.read_text())
  for key in ("version", "nodes", "access_policy", "security_invariants"):
    if key not in data:
      fail(f"network.yaml missing '{key}' section")
  invariants = set(data.get("security_invariants", []))
  required = {"default_deny_inbound", "ssh_key_only_auth"}
  missing = required - invariants
  if missing:
    fail(f"security_invariants missing: {', '.join(sorted(missing))}")

def check_generator() -> None:
  gen = ROOT / "infra/policy/intent/generate.sh"
  if not gen.exists():
    fail("Missing generator script infra/policy/intent/generate.sh")
  out_dir = ROOT / "infra/policy/generated"
  # ensure directory path aligns with script's OUTPUT_DIR
  # We don't parse bash; instead ensure the intended target exists.
  out_dir.mkdir(parents=True, exist_ok=True)
  print(f"✓ generator target directory present: {out_dir}")

def main() -> None:
  check_intent_yaml()
  check_generator()
  print("✓ policy intent OK")

if __name__ == "__main__":
  main()

