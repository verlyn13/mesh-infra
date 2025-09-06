#!/bin/bash
# Transforms vendor-neutral policy to implementation-specific configs

set -euo pipefail

POLICY_FILE="network.yaml"
OUTPUT_DIR="../generated"

mkdir -p "$OUTPUT_DIR"

# For now, we'll generate Tailscale ACLs
# TODO: Add WireGuard config generation as fallback

echo "Generating Tailscale ACL from $POLICY_FILE..."

cat > "$OUTPUT_DIR/tailscale-acl.json" << 'EOJSON'
{
  "tagOwners": {
    "tag:server": ["verlyn13@github"],
    "tag:workstation": ["verlyn13@github"]
  },
  "acls": [
    {
      "action": "accept",
      "src": ["verlyn13@github"],
      "dst": ["*:*"]
    },
    {
      "action": "accept",
      "src": ["tag:workstation"],
      "dst": ["tag:server:22,443,8080"]
    }
  ],
  "ssh": [
    {
      "action": "accept",
      "src": ["verlyn13@github"],
      "dst": ["tag:server"],
      "users": ["verlyn13", "root"]
    }
  ]
}
EOJSON

echo "✓ Generated Tailscale ACL"
echo "Files created in $OUTPUT_DIR/"