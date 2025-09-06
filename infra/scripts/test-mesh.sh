#!/usr/bin/env bash
set -euo pipefail

echo "== Mesh Connectivity Smoke Test =="

if ! command -v tailscale >/dev/null 2>&1; then
  echo "tailscale not installed or not in PATH" >&2
  exit 1
fi

echo "-- tailscale status --"
tailscale status || true

nodes=("hetzner-hq" "laptop-hq" "wsl-hq")

echo "-- ping via tailscale (logical names) --"
for n in "${nodes[@]}"; do
  if tailscale ping -c 1 "$n" >/dev/null 2>&1; then
    echo "✓ reachable: $n"
  else
    echo "✗ unreachable: $n"
  fi
done

echo "-- check routes --"
ip route show table all | grep -E "(tailscale|ts0)" || echo "no explicit tailscale routes found"

echo "✓ mesh test complete"

