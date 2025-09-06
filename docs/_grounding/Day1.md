# Day 1 Setup Guide (Grounding)

This document captures the human‑approved Day 1 bootstrap for the three nodes.

- Nodes: hetzner (hub), laptop (workstation), wsl (workstation)
- Mesh: Tailscale primary, WireGuard fallback

Quick start (human‑run only):

```bash
make init-day1
# then verify
tailscale status
```

Notes:
- Emergency access documented in `infra/ESCAPE_HATCHES.md`.
- Agents must not modify this file.

