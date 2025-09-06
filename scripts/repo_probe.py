#!/usr/bin/env python3
"""Generate repository snapshot for state tracking"""

import json
import subprocess
from pathlib import Path
from datetime import datetime

def get_git_info():
    """Get current git state"""
    return {
        "head": subprocess.run(["git", "rev-parse", "HEAD"], 
                              capture_output=True, text=True).stdout.strip()[:8],
        "branch": subprocess.run(["git", "branch", "--show-current"], 
                                capture_output=True, text=True).stdout.strip(),
        "dirty": bool(subprocess.run(["git", "diff", "--quiet"], 
                                    capture_output=True).returncode)
    }

def scan_infrastructure():
    """Scan infrastructure files"""
    infra_path = Path("infra")
    return {
        "scripts": len(list(infra_path.glob("scripts/*.sh"))),
        "policies": len(list(infra_path.glob("policy/intent/*.yaml"))),
        "backups": infra_path.joinpath("backup/wg").exists()
    }

def generate_snapshot():
    """Generate complete snapshot"""
    snapshot = {
        "timestamp": datetime.now().isoformat(),
        "git": get_git_info(),
        "infrastructure": scan_infrastructure(),
        "nodes": {
            "configured": ["hetzner", "laptop", "wsl"],
            "mesh_network": "10.0.0.0/24"
        }
    }
    
    output_path = Path("docs/_generated/snapshot.json")
    output_path.parent.mkdir(exist_ok=True, parents=True)
    
    with open(output_path, 'w') as f:
        json.dump(snapshot, f, indent=2)
    
    print(f"Snapshot saved to {output_path}")
    return snapshot

if __name__ == "__main__":
    generate_snapshot()