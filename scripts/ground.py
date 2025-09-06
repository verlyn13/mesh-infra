#!/usr/bin/env python3
"""
Ground CLI - Agent interface to repository state
Usage:
  ground pull    - Read current state
  ground plan    - Create session plan
  ground commit  - Validate and prepare commit
"""

import json
import yaml
import sys
import subprocess
from pathlib import Path
from datetime import datetime, date

class DateTimeEncoder(json.JSONEncoder):
    """Handle datetime objects in JSON serialization"""
    def default(self, obj):
        if isinstance(obj, (datetime, date)):
            return obj.isoformat()
        return super().default(obj)

def pull():
    """Load and display current repository state"""
    facts = Path("docs/_grounding/facts.yml")
    if facts.exists():
        with open(facts) as f:
            data = yaml.safe_load(f)
        print(json.dumps(data, indent=2, cls=DateTimeEncoder))
    
    # Show git status
    result = subprocess.run(["git", "status", "--short"], capture_output=True, text=True)
    if result.stdout:
        print("\nUncommitted changes:")
        print(result.stdout)

def plan():
    """Create a new session plan"""
    session_id = datetime.now().strftime("%Y%m%d-%H%M%S")
    commit = subprocess.run(["git", "rev-parse", "HEAD"], capture_output=True, text=True).stdout.strip()
    
    session = {
        "session_id": session_id,
        "started_at": datetime.now().isoformat(),
        "agent": "unknown",  # Agent should specify
        "commit": commit[:8],
        "scope": {
            "include": [],
            "exclude": ["docs/_grounding/*", "infra/policy/intent/*"]
        },
        "goals": [],
        "constraints": [
            "Do not modify grounding files",
            "All changes must have tests",
            "Update snapshot before commit"
        ]
    }
    
    session_file = Path(f".session/session-{session_id}.yaml")
    session_file.parent.mkdir(exist_ok=True)
    
    with open(session_file, 'w') as f:
        yaml.dump(session, f)
    
    print(f"Created session: {session_file}")
    return str(session_file)

def commit():
    """Validate changes before commit"""
    import os
    
    # Check for grounding file modifications
    result = subprocess.run(["git", "diff", "--name-only", "docs/_grounding/"], 
                          capture_output=True, text=True)
    if result.stdout:
        print("ERROR: Grounding files modified!")
        print(result.stdout)
        sys.exit(1)
    
    # Run doc check if it exists
    doc_check = Path("scripts/doc_check.py")
    if doc_check.exists():
        print("Running documentation checks...")
        result = subprocess.run([sys.executable, str(doc_check)], capture_output=True, text=True)
        if result.returncode != 0:
            print("Documentation check failed:")
            print(result.stdout)
            if result.stderr:
                print(result.stderr)
            sys.exit(1)
        print("✓ Documentation checks passed")
    
    # Run policy check if it exists
    policy_check = Path("scripts/policy_check.py")
    if policy_check.exists():
        print("Running policy checks...")
        result = subprocess.run([sys.executable, str(policy_check)], capture_output=True, text=True)
        if result.returncode != 0:
            print("Policy check failed:")
            print(result.stdout)
            if result.stderr:
                print(result.stderr)
            sys.exit(1)
        print("✓ Policy checks passed")
    
    # Regenerate snapshot
    print("Regenerating snapshot...")
    probe_script = Path("scripts/repo_probe.py")
    if probe_script.exists():
        subprocess.run([sys.executable, str(probe_script)])
    
    print("✓ Ready to commit")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    
    command = sys.argv[1]
    if command == "pull":
        pull()
    elif command == "plan":
        plan()
    elif command == "commit":
        commit()
    else:
        print(f"Unknown command: {command}")
        sys.exit(1)
