#!/usr/bin/env python3
"""Validate docs structure and README references.

Checks:
- Required grounding files exist.
- README links to existing docs files.
- ADR directory present with at least one entry or index.
"""

from __future__ import annotations
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent

def fail(msg: str) -> None:
  print(f"ERROR: {msg}")
  sys.exit(1)

def check_grounding_files() -> None:
  base = REPO_ROOT / "docs/_grounding"
  required = [
    base / "facts.yml",
    base / "module_map.json",
    base / "roadmap.md",
  ]
  missing = [str(p) for p in required if not p.exists()]
  if missing:
    fail(f"Missing required grounding files: {', '.join(missing)}")

def check_readme_links() -> None:
  readme = (REPO_ROOT / "README.md").read_text(encoding="utf-8", errors="ignore")
  # crude regex for markdown links: [text](path)
  links = re.findall(r"\[[^\]]+\]\(([^)]+)\)", readme)
  doc_links = [l for l in links if l.startswith("docs/") or l.startswith("infra/")]
  missing = [l for l in doc_links if not (REPO_ROOT / l).exists()]
  if missing:
    fail(f"README links point to missing files: {', '.join(missing)}")

def check_adr_dir() -> None:
  adr = REPO_ROOT / "docs/_grounding/adr"
  if not adr.exists():
    fail("Missing ADR directory at docs/_grounding/adr")
  entries = list(adr.glob("*.md"))
  if not entries and not (adr / "README.md").exists():
    fail("ADR directory exists but has no entries or index")

def main() -> None:
  check_grounding_files()
  check_readme_links()
  check_adr_dir()
  print("✓ docs structure OK")

if __name__ == "__main__":
  main()

